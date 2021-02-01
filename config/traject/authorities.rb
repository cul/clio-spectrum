# To have access to various built-in logic
# for pulling things out of MARC21, like `marc_languages`
require 'traject/macros/marc21_semantics'
extend  Traject::Macros::Marc21Semantics

# To have access to the traject marc format/carrier classifier
require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats

Marc21 = Traject::Macros::Marc21 # shortcut

# Explicitly require, to allow ActiveRecord calls within Traject
require 'local_subject'


# Which authorized heading fields do we care about?
# Any kind of person, any topic, or any Geo term,
# because any of these could be used in a bib record's
# author field or subject field.
# see: https://www.loc.gov/marc/authority/ad1xx3xx.html
#   - 100 - Personal Name
#   - 110 - Corporate Name
#   - 111 - Meeting Name
#   - 150 - Topical Term
#   - 151 - Geographic Name
interesting_fields = %w(100 110 111 150 151)
# for faster testing, use a subset...
# interesting_fields = ['151']

# Any fields with any of these subfields should be ignored for
# our purposes.  (Subdivisions, Title, etc.)
disqualifying_subfields = %w(k t v x y z)
disqualifiers = disqualifying_subfields.join

# Loop to skip over any Authority records we're not interested in.
# For now only:
# - Name Authority records, but not qualified Name records
# - Subject Authority Records, Topical or Geographic, also unqualified
# - And skip if there are no variants
each_record do |record, context|
  authority_id = record['001'].value
  
  # NEXT-1601 - local subject headings
  # Beyond the regular 1xx$a replacement rules, we need to catch 180$x
  #   180 - Heading-General Subdivision, $x - General subdivision 
  # Special-case this, it doesn't fit into the below logic at all.
  # Only insert database record for the swap, 
  # then let the rest of the logic consider whether this record
  # gets added to Solr or not.
  if record['180'].present? && record['180']['x'].present?
    loc_subject = record['180']['x']

    record.fields('480').each do |field480|
      next unless field480['5'] == 'NNC'
      
      # We've found a locally defined subject variant!
      nnc_subject = field480['x']
      puts "DEBUG - 180$x - authority_id='#{authority_id}' loc_subject='#{loc_subject}' nnc_subject='#{nnc_subject}'" if ENV['DEBUG']
      LocalSubject.where(loc_subject: loc_subject).delete_all
      LocalSubject.create(authority_id: authority_id, loc_subject: loc_subject, nnc_subject: nnc_subject)
      ActiveRecord::Base.clear_active_connections!
    end
  end
  
  
  # # abort after a certain number of records
  # raise "EARLY ABORT FOR TESTING" if context.position > 100

  # assume we're going to skip this record, unless we find something interesting.
  skip = true
  # store subfield 'a' for debugging
  loc_subject = nil

  interesting_fields.each do |field|
    # Is one of the interesting authorized headings found in the record?
    next unless record[field].present?
    # ... with a name subfield ($a)?
    next unless record[field]['a'].present?
    loc_subject = record[field]['a']
    # ... and without further qualification (subdivision, subheading)?
    all_subfields = record[field].subfields.map(&:code)
    # (intersection must be empty)
    next unless (all_subfields & disqualifying_subfields).empty?

    # OK, looks like this record has an authorized term we might care about.
    # Now, are there also any variant forms present?

    # (determine the tracings from the field tag)
    see_from_tag = field.sub(/^1/, '4')
    see_also_tag = field.sub(/^1/, '5')

    # Do we have at least one tracing, with an 'a' subfield?
    next unless (record[see_from_tag].present? && record[see_from_tag]['a'].present?) ||
                (record[see_also_tag].present? && record[see_also_tag]['a'].present?)
    # ... if yes, then KEEP THIS RECORD!
    # DEBUG
    # puts "KEEP auth id #{record['001'].value} (\"#{loc_subject}\")"
    skip = false
    
    
    # NEXT-1601 - LOCAL SUBJECTS - If any of our "see_from" fields is a local NNC variant,
    # record this to a mapping used for rewriting the term in the discovery interface.
    record.fields(see_from_tag).each do |see_from_field|
      next unless see_from_field['5'] == 'NNC'
      
      # We've found a locally defined subject variant!
      nnc_subject = see_from_field['a']
      puts "DEBUG authority_id='#{authority_id}' loc_subject='#{loc_subject}' nnc_subject='#{nnc_subject}'" if ENV['DEBUG']
      LocalSubject.where(loc_subject: loc_subject).delete_all
      LocalSubject.create(authority_id: authority_id, loc_subject: loc_subject, nnc_subject: nnc_subject)
      ActiveRecord::Base.clear_active_connections!
    end
    
  end

  # When "skip" is still true, we never found a reason to keep this record.
  # context.skip is noisy - it'll print a line of output to DEBUG for each
  # record skipped.  We may as well try to output useful details.
  next unless skip
  note = loc_subject.nil? ? '(no authorized name field)' : "(\"#{loc_subject}\")"
  context.skip!("skipping auth id #{record['001'].value} #{note}")
  next
end

# We've now skipped over 90% of the input records.  That'll help
# with size/performance/etc.
# The current authority record is potentially useful.
# Now we'll get specific about how to build the Solr authority record.

to_field 'id', extract_marc('001', first: true)

# Authority records can be huge.
# Geographic Authority record 198484, Turkey, is over the 32K limit
# on Solr 'String' fields.
# Solr 'Text' fields have a higher limit.  Although we don't really
# want to analyze the full MARC record, we need to use this field-type.
to_field 'marc_txt', serialized_marc(format: 'xml')

# no, don't include this very large data until we really need it
# # This might be useful in the future.
# to_field 'text', extract_all_marc_values

###  Store authorized forms separately

# Author Authorized form (Personal, Corporate or Meeting Name)
to_field 'author_t', extract_marc('100abcdgqu:110abcdgnu:111acdegjnqu', trim_punctuation: false)

# Subject Authorized form (Topical Term)
to_field 'subject_t', extract_marc('150a', trim_punctuation: false)

# Geo Authorized form (Geographic Name)
to_field 'geo_t', extract_marc('151a', trim_punctuation: false)

###  COMBINED AUTHOR+SUBJECT+GEO FIELDS

# This is the matcher field used during bib record indexing.
# Full authorized terms from the bib record will be matched against this field.
# We need to bring in many subfields for better precision in matching.
#
# If doing exact string match (_s), query term must include the same subfields.
# Solr text field allowed fuzzy matching (American == American Airlines)
# to_field "authorized_t", extract_marc("100abcdgqu:110abcdgnu:111acdegjnqu:150a:151a", trim_punctuation: false)
#
# Solr string field for precise match only (American != American Airlines)
# AND:  we'll add the disqualifying subfields here as a backup safety measure.
#  If by mistake "$a India $x Foreign relations" isn't skipped (as it should
# have been above), then insert with authorized form "India Foreign relations"
# instead of "India", so it doesn't clobber our base "India" record.
# to_field "authorized_s", extract_marc("100abcdgqu:110abcdgnu:111acdegjnqu:150a:151a", trim_punctuation: false)
#
# SWITCH from _s to _ss, because this is now a multivalued field.
# (multivalued?  yes, for Geo we support both the 151a and the 781zz as authorized)
to_field 'authorized_ss', extract_marc("100abcdgqu#{disqualifiers}:110abcdgnu#{disqualifiers}:111acdegjnqu#{disqualifiers}:150a#{disqualifiers}:151a#{disqualifiers}:781zz", trim_punctuation: false)

# The Variant list is used to improve retrieval from patron queries.
# Keep this focused on what a patron might search by, that is,
# omit special code subfields.
to_field 'variant_t' do |record, accumulator, _context|
  # DEBUG
  # puts "started variant_t for #{record['001'].value}"

  # 4xx - See From Tracing Fields
  # 5xx - See Also Tracing Fields
  # NEXT-1331 - Drop the '550' altogether
  record.fields(%w(400 410 411 450 451
                   500 510 511 551)).each do |field|

    # DEBUG
    # puts "-- record #{record['001'].value}, field #{field}"
    # We need a name/term field
    next unless field['a']

    # Ignore tracings that aren't the same 'kind' as the authorized form
    # e.g., here's a Personal Name with a See Also Corporate Name
    #   100 10 $a Comonfort, Ignacio, $d 1812-1863
    #   510 10 $a Mexico. $b President (1855-1858 : Comonfort)
    authorized_field = field.tag.sub(/^[45]/, '1')
    next unless record[authorized_field]

    # If this variant term has the exact same subfield 'a' value, skip it,
    # it's not useful for improving retrieval.
    # e.g:  110 1#  $a Honduras.  $b Oficina de Estudios Territoriales
    #       410 1#  $a Honduras.  $b Estudios Territoriales, Oficina de
    # DEBUG
    # puts "-- 000000  skipping #{field['a']} for #{record['001'].value}" if field['a'] == record[authorized_field]['a']
    next if field['a'] == record[authorized_field]['a']

    # Check all the subfields of this field...
    all_subfields = field.subfields.map(&:code)
    # ... against the "disqualifying" list.  (intersection must be empty)
    next unless (all_subfields & disqualifying_subfields).empty?

    # Exclude certain 5XX fields - e.g., Hierarachical superior
    next if field['i'].present? && field['i'] == 'Hierarchical superior'

    # Ok, there's an "a", and no bad subfields, so yes, we want this variant.
    # Gather up any subfields that might be useful
    #
    # Start with abcdeq, see how this goes...
    # accumulator << field['abcdeq']  <--- can't do this
    # variant_string = ['a','b','c','d','e','q'].map {|code| field[code]}.compact.join(' ')
    #
    # This many subfields will make for very fat variant strings.
    # That may lead to retrieving too many records.
    # Let's keep it simpler.  How about just 'a'?  Let's try.
    variant_string = ['a'].map { |code| field[code] }.compact.join(' ')
    # DEBUG
    # puts "-- adding  variant_string:#{field}"
    accumulator << variant_string
  end
end


