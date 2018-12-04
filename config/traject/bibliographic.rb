# To have accumulatoress to various built-in logic
# for pulling things out of MARC21, like `marc_languages`
require 'traject/macros/marc21_semantics'
extend  Traject::Macros::Marc21Semantics

# To have accumulatoress to the traject marc format/carrier classifier
require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats

# Columbia's local format classification rules
extend FormatMacro

# require 'traject/macros/marc21'
# extend  Traject::Macros::Marc21
require 'traject/indexer'
require 'traject/macros/marc21'

require 'traject_utility'

# # Try U.Mich's more detailed format classifier
# require 'traject/umich_format'
# extend Traject::UMichFormat::Macros

# shortcuts
Marc21 = Traject::Macros::Marc21
MarcFormats = Traject::Macros::MarcFormats

bibs = 0
lookups = 0

ATOZ = ('a'..'z').to_a.join('')

# Authority counter variables
author_variant_count = 0
subject_variant_count = 0
geo_variant_count = 0

# Pre-load translation maps once, not once per record
country_map = Traject::TranslationMap.new('country_map')
callnumber_map = Traject::TranslationMap.new('callnumber_map')

# # DEBUGGING
# each_record do |record, context|
#   # --- read all records but do no indexing
#   # context.skip!("bib #{record['001'].value}")
#   # --- read & skip all records except for a specific bib
#   # if record['001'].value != '402647'
#   #   context.skip!
#   # end
# end

# Set any local variables to be used repeatedly in below logic
recap_location_code = ''
recap_location_name = ''

each_record do |record, _context|
  # SCSB ReCAP - re-set the value for each record
  first_location_code = Marc21.extract_marc_from(record, '852b', first: true).first
  if first_location_code.present? && first_location_code.match(/^scsb/)
    recap_location_code = first_location_code
    recap_location_name = TrajectUtility.recap_location_code_to_label(recap_location_code)
  end
  # Reset authorities counter variables for each new record
  author_variant_count = 0
  subject_variant_count = 0
  geo_variant_count = 0
end

to_field 'id', extract_marc('001', first: true)

to_field 'marc_display', serialized_marc(format: 'xml')

# This calculates a single timestamp and applies it to all records
# to_field "marc_dt", literal(Time.now.utc.iso8601)
# This calculates a timestamp for each record as it is processed
to_field 'marc_dt' do |_record, accumulator|
  accumulator << Time.now.utc.iso8601
end

# to_field "text", extract_all_marc_values(from: '050', to: '850')
to_field 'text', extract_all_marc_values(from: '010', to: '852') do |record, accumulator|
  extra_fields = []

  # # 035$a - System Control Number
  # extra_fields << Marc21.extract_marc_from(record, '035a')
  # # 852$x - Staff Note
  # extra_fields << Marc21.extract_marc_from(record, '852x')
  # 876$p - Barcode
  extra_fields << Marc21.extract_marc_from(record, '876p')
  # 891$c, $a, $e - Donor Info ('Gift', donor name, donor code)
  extra_fields << Marc21.extract_marc_from(record, '891cae')
  # 948$A-Z - Processing Information
  extra_fields << Marc21.extract_marc_from(record, "948#{ATOZ}")
  # 965$a - Collection Description
  extra_fields << Marc21.extract_marc_from(record, '965a')
  # 960$f - Invoice Number
  extra_fields << Marc21.extract_marc_from(record, '960f')
  # 960$u - Fund Code
  extra_fields << Marc21.extract_marc_from(record, '960u')
  # 992$a - Normalized Location Name (location facet term)
  extra_fields << Marc21.extract_marc_from(record, '992a')

  accumulator << extra_fields.flatten.join(' ')
end

to_field 'author_txt', extract_marc('100abcdjq:110abcdjq:111abcdjq', trim_punctuation: false)
to_field 'author_addl_txt', extract_marc('700abcdjq:710abcdjq:711abcdjq', trim_punctuation: false)
to_field 'author_facet', extract_marc("100abcdq:110#{ATOZ}:111#{ATOZ}:700abcdq:710#{ATOZ}:711#{ATOZ}", trim_punctuation: true, alternate_script: false)
to_field 'author_display', extract_marc("100abcdq:110#{ATOZ}:111#{ATOZ}", trim_punctuation: true, alternate_script: false)
to_field 'author_vern_display', extract_marc("100abcdq:110#{ATOZ}:111#{ATOZ}", trim_punctuation: true, alternate_script: :only)
to_field 'author_sort', marc_sortable_author

# Using the same author forms as used for author_facet,
# lookup each value to get a
to_field 'author_variant_txt' do |record, accumulator|
  # fetch all author forms from the various MARC fields
  author_fields = "100abcdq:110#{ATOZ}:111#{ATOZ}:700abcdq:710#{ATOZ}:711#{ATOZ}"
  all_authors = Marc21.extract_marc_from(record, author_fields, trim_punctuation: true, alternate_script: false).flatten.uniq

  # Lookup variants for each author
  # (Lookup each author, in one-by-one single-param queries?
  #  Or join all authors terms w/OR into a single giant Solr query?
  #  For now, try simple single-term queries. Individually faster, and maybe better caching?)
  all_variants = []
  all_authors.each do |author|
    all_variants << lookup_variants(author)
  end

  all_variants.flatten.uniq.each do |variant|
    author_variant_count += 1
    accumulator << variant
  end
end

to_field 'title_txt', extract_marc('245afknp', trim_punctuation: false, alternate_script: true)
to_field 'title_display', extract_marc('245abfhknp', trim_punctuation: true, alternate_script: false)
to_field 'title_vern_display', extract_marc('245abfhknp', trim_punctuation: true, alternate_script: :only)
to_field 'title_filing_txt', extract_marc_filing_version('245a')
to_field 'title_filing_full_txt', extract_marc_filing_version('245ab')
to_field 'subtitle_txt', extract_marc('245b', trim_punctuation: true, alternate_script: true)
to_field 'title_first_facet', marc_sortable_title do |_record, accumulator|
  accumulator.map! do |title|
    if title.strip.first =~ /\d/
      '0-9'
    else
      title.strip.first.upcase
    end
  end
end
to_field 'title_addl_txt', extract_marc("245abnps:130#{ATOZ}:240abcdefgklmnopqrs:210ab:222ab:242abnp:243abcdefgklmnopqrs:246abcdefgnp:247abcdefgnp:780#{ATOZ}:785#{ATOZ}:700gklmnoprst:710fgklmnopqrst:711fgklnpst:730abcdefgklmnopqrst:740anp", trim_punctuation: false, alternate_script: true)
to_field 'title_series_txt', extract_marc("830#{ATOZ}", trim_punctuation: true, alternate_script: true)
to_field 'title_series_display', extract_marc("830#{ATOZ}", trim_punctuation: true, alternate_script: false)
to_field 'title_sort', marc_sortable_title do |_record, accumulator|
  accumulator.map! { |title| title.strip.gsub(/[^[:word:]\s]/, '').downcase }
end

to_field 'subject_txt', extract_marc("600#{ATOZ}:610#{ATOZ}:611#{ATOZ}:630#{ATOZ}:648#{ATOZ}:650#{ATOZ}:651#{ATOZ}:653aa:654#{ATOZ}:655#{ATOZ}", trim_punctuation: true, alternate_script: true)
to_field 'subject_topic_facet', extract_marc('600abcdq:600x:610ab:610x:611ab:611x:630a:630x:650a:650x:651x:655x', trim_punctuation: true, alternate_script: false)
to_field 'subject_era_facet', extract_marc('600y:610y:611y:630y:650y:651y:655y', trim_punctuation: true, alternate_script: false)
to_field 'subject_geo_facet', extract_marc('600z:610z:611z:630z:650z:651a:651z:655z', trim_punctuation: true, alternate_script: false)
to_field 'subject_form_facet', extract_marc('600v:610v:611v:630v:650v:651v:655ab:655v', trim_punctuation: true, alternate_script: false)
to_field 'subject_form_txt', extract_marc('600v:610v:611v:630v:650v:651v:655ab:655v', trim_punctuation: true, alternate_script: false)

# Lookup subject variants, using the same subject terms as used for subject_topic_facet,
to_field 'subject_variant_txt' do |record, accumulator|
  # fetch all subject (topic) forms from the various MARC fields
  subject_fields = '600abcdq:600x:610ab:610x:611ab:611x:630a:630x:650a:650x:651x:655x'
  all_subjects = Marc21.extract_marc_from(record, subject_fields, trim_punctuation: true, alternate_script: false).flatten.uniq

  # Lookup variants for each subject
  all_variants = []
  all_subjects.each do |subject|
    all_variants << lookup_variants(subject)
  end

  all_variants.flatten.uniq.each do |variant|
    next unless variant.present?
    subject_variant_count += 1
    accumulator << variant
    # DEBUG
    # puts "subject_variant_count=#{subject_variant_count} variant=#{variant}"
  end
end

# 781z - geographic subfield divisions, need the value as query into authorities solr
# "For single subfield specifications, you force concatenation by
#  repeating the subfield specification""
to_field 'geo_subdivision_txt', extract_marc('600zz:610zz:611zz:630zz:650zz:651zz:655zz', trim_punctuation: true)

# Geo is tricky.
# A Geo term in the Bib record might look like this:
#    651 _0 ǂa Mumbai (India)
# Or like this (in 'subdivision' format):
#    6XX XX ... ǂz India ǂz Mumbai
# The Authority record (indexed to the Authorites Solr) will have multiple forms, e.g:
#    151 __ ǂa Mumbai (India)
#    451 __ ǂa Asumumbay (India)
#    551 __ ǂa Bombay (India)
#    781 _0 ǂz India ǂz Mumbai
# We need enable matches via either the Authority 151 or the Authority 781.
# So we need to index our bib fields both as singletons and as concatenations.
to_field 'geo_variant_txt' do |record, accumulator|
  geo_terms = '600z:610z:611z:630z:650z:651a:651z:655z'
  geo_subdivs = '600zz:610zz:611zz:630zz:650zz:651zz:655zz'
  geo_fields = "#{geo_terms}:#{geo_subdivs}"
  all_geo = Marc21.extract_marc_from(record, geo_fields, trim_punctuation: true, alternate_script: false).flatten.uniq

  # Lookup variants for each geo entry
  all_variants = []
  all_geo.each do |geo|
    all_variants << lookup_variants(geo)
  end

  all_variants.flatten.uniq.each do |variant|
    geo_variant_count += 1
    accumulator << variant
  end
end

to_field 'pub_place_display', extract_marc('260a:264a', trim_punctuation: true, alternate_script: false)
to_field 'pub_name_display', extract_marc('260b:264b', trim_punctuation: true, alternate_script: false)
to_field 'pub_year_display', extract_marc('260c:264c', trim_punctuation: true, alternate_script: false)
to_field 'pub_place_txt', extract_marc('260a:264a', trim_punctuation: true, alternate_script: false)
to_field 'pub_name_txt', extract_marc('260b:264b', trim_punctuation: true, alternate_script: false)
to_field 'pub_year_txt', extract_marc('260c:264c', trim_punctuation: true, alternate_script: false)

to_field 'pub_date_txt', marc_publication_date(estimate_tolerance: 100)

to_field 'pub_country_facet' do |record, accumulator|
  if record['008']
    value = record['008'].value[15..17]
    next unless value
    # Need to pre-process country code to strip spaces, etc. before table lookup.
    country = country_map[value.gsub(/[^a-z]/, '')]
    # country may be string ("Peru") or array (["Canada", "Canada - Alberta"]),
    # support either with: .concat( Array(X) )
    accumulator.concat(Array(country))
  end
end

to_field 'language_facet', extract_marc('008[35-37]:041a:041d', translation_map: 'language_map')

# Rails rewrite of Columbia format classificaiton rules from the original Perl
# (found in lib/format_macro.rb)
to_field 'format', columbia_format

to_field 'lc_1letter_facet', extract_marc('990a') do |_record, accumulator|
  accumulator.map! do |value|
    # Traject::TranslationMap.new("callnumber_map")[value.first]
    callnumber_map[value.first]
  end
end
to_field 'lc_2letter_facet', extract_marc('990a', translation_map: 'callnumber_full_map')
to_field 'lc_subclass_facet', extract_marc('990a', translation_map: 'callnumber_full_map')

to_field 'clio_id_display', extract_marc('001', first: true, trim_punctuation: true)

to_field 'acq_dt' do |record, accumulator|
  tag997a = Marc21.extract_marc_from(record, '997a', first: true, trim_punctuation: true).first
  # Acquisition Date should look like:  2017-08-20T00:00:00.000Z
  accumulator << tag997a if tag997a =~ /[\d\-]+T[\d\:\.]+Z/
end

to_field 'source_facet', extract_marc('995a', trim_punctuation: true)
to_field 'source_display', extract_marc('995a', trim_punctuation: true)

to_field 'repository_facet', extract_marc('996a', trim_punctuation: true)
to_field 'repository_display', extract_marc('996a', trim_punctuation: true)

to_field 'boost_exact', extract_marc('999a', trim_punctuation: true)

to_field 'database_restrictions_display', extract_marc('506a', trim_punctuation: false)
to_field 'database_discipline_facet', extract_marc('967a', translation_map: 'database_discipline_map')
to_field 'database_resource_type_facet', extract_marc('966a', translation_map: 'database_resource_type_map')

to_field 'summary_display', extract_marc("520#{ATOZ}", trim_punctuation: false)

# Searchable ISBN: consider both the 020a and 020z, as 10- or 13-digit
to_field 'isbn_txt', extract_marc('020az', separator: nil) do |_record, accumulator|
  original = accumulator.dup
  accumulator.map! { |isbn| StdNum::ISBN.allNormalizedValues(isbn) }
  accumulator << original
  accumulator.flatten!
  accumulator.uniq!
end

# Displayed ISBN - only the primary 020a, cleaned but otherwise as-given
ISBN_CLEAN = /([\- \d]*[X\d])/
to_field 'isbn_display', extract_marc('020a') do |_record, accumulator|
  accumulator.map! do |isbn|
    if clean_isbn = isbn.match(ISBN_CLEAN)
      clean_isbn[1]
    end
  end
end

ISSN_CLEAN = /(\d{4}-\d{3}[X\d])/

to_field 'issn_txt', extract_marc('022a:022l:022y:775x:776x') do |_record, accumulator|
  accumulator.map! do |issn|
    if clean_issn = issn.match(ISSN_CLEAN)
      clean_issn[1]
    end
  end
end
to_field 'issn_display', extract_marc('022a') do |_record, accumulator|
  accumulator.map! do |issn|
    if clean_issn = issn.match(ISSN_CLEAN)
      clean_issn[1]
    end
  end
end

to_field 'lccn_display', extract_marc('010a', trim_punctuation: true)
to_field 'lccn_txt', extract_marc('010a:010z', trim_punctuation: true)

OCLC_CLEAN = /^\(OCoLC\)[^0-9A-Za-z]*([0-9A-Za-z]*)[^0-9A-Za-z]*$/

to_field 'oclc_txt', extract_marc('035a') do |_record, accumulator|
  accumulator.map! do |oclc|
    if clean_oclc = oclc.match(OCLC_CLEAN)
      clean_oclc[1]
    end
  end
end
to_field 'oclc_display', extract_marc('035a') do |_record, accumulator|
  accumulator.map! do |oclc|
    if clean_oclc = oclc.match(OCLC_CLEAN)
      clean_oclc[1]
    end
  end
end

to_field 'full_publisher_display', extract_marc("260#{ATOZ}:264#{ATOZ}", trim_punctuation: false, alternate_script: false)

# LOCATION_CALL_NUMBER = /^(.*)\|DELIM\|.*/
CALL_NUMBER_ONLY = /^.* \>\> (.*)\|DELIM\|.*/

# Local field 992 is created by the exract processing.
# $b is a composite: location-label,  '>>', call-number, '|DELIM|', holdings-id
# e.g.
# Offsite - Place Request for delivery within 2 business days >> GR359 .G64 1999g|DELIM|3507870
to_field 'location_call_number_id_display', extract_marc('992b', trim_punctuation: true) do |_record, accumulator|
  # Add SCSB partner location name, if there is one
  accumulator << recap_location_name if recap_location_name.present?
end

to_field 'location_call_number_txt', extract_marc('992b', trim_punctuation: true) do |_record, accumulator|
  accumulator.map! do |value|
    value.split('|DELIM|').first
  end
  # Add SCSB partner location name, if there is one
  accumulator << recap_location_name if recap_location_name.present?
end

to_field 'call_number_txt', extract_marc('992b', trim_punctuation: true) do |_record, accumulator|
  accumulator.map! do |value|
    if clean_value = value.match(CALL_NUMBER_ONLY)
      clean_value[1]
    end
  end
end
to_field 'call_number_display', extract_marc('992b', trim_punctuation: true) do |_record, accumulator|
  accumulator.map! do |value|
    if clean_value = value.match(CALL_NUMBER_ONLY)
      clean_value[1]
    end
  end
end

to_field 'location_facet', extract_marc('992a', trim_punctuation: true) do |_record, accumulator|
  # Add SCSB partner location name, if there is one
  accumulator << recap_location_name if recap_location_name.present?
end

to_field 'location_txt', extract_marc('852ab:992ab', trim_punctuation: true) do |_record, accumulator|
  accumulator.map! do |value|
    value.split('|DELIM|').first
  end

  # Add SCSB partner location name, if there is one
  accumulator << recap_location_name if recap_location_name.present?
end

to_field 'url_munged_display' do |record, accumulator|
  record.fields('856').each do |field856|
    next unless field856.indicator1 == '4'
    accumulator << [field856.indicator2, field856['3'], field856['u'], field856['z']].join('|||')
  end
end

# Shelf Browse support fields

to_field 'shelfkey' do |record, accumulator|
  id = Marc21.extract_marc_from(record, '001', first: true).first
  record.fields('991').each do |field991|
    next unless field991 && field991['b']
    accumulator << "#{field991['b'].downcase}+#{id}"
  end
end
to_field 'reverse_shelfkey' do |record, accumulator|
  id = Marc21.extract_marc_from(record, '001', first: true).first
  record.fields('991').each do |field991|
    next unless field991 && field991['b']
    accumulator << TrajectUtility.reverseString("#{field991['b'].downcase}+#{id}")
  end
end

to_field 'item_display' do |record, accumulator|
  id = Marc21.extract_marc_from(record, '001', first: true).first
  record.fields('991').each do |field991|
    next unless field991 && field991['a'] && field991['b']
    display_call_number = field991['a']
    shelfkey = "#{field991['b'].downcase}+#{id}"
    reverse_shelfkey = TrajectUtility.reverseString("#{field991['b'].downcase}+#{id}")
    accumulator << display_call_number + ' | ' + shelfkey + ' | ' + reverse_shelfkey
  end
end

# https://wiki.library.columbia.edu/display/cliogroup/Holdings+Revision+project
# 852$0 - Traject extraction specification:  8520
to_field 'mfhd_id', extract_marc('8520')
# 876$p - Barcode, if physical.  Repeated field.
to_field 'barcode_txt', extract_marc('876p')

# Count of URLs (856 fields) within this record
to_field 'urls_i' do |record, accumulator|
  count = 0
  record.fields('856').each do |field856|
    next unless field856.indicator1 == '4'
    count += 1
  end
  accumulator << count
end

# Count of Holdings (852$0) within this record
to_field 'holdings_i' do |record, accumulator|
  count = 0
  record.fields('852').each do |field852|
    next unless field852 && field852['0']
    count += 1
  end
  accumulator << count
end

# Count of Items (876$a) within this record
# (not really all that reliable...)
to_field 'items_i' do |record, accumulator|
  count = 0
  record.fields('876').each do |field876|
    next unless field876 && field876['a']
    count += 1
  end
  accumulator << count
end

# Datestamp for when Authorities were filled in.
to_field 'authorities_dt' do |_record, accumulator|
  accumulator << Time.now.utc.iso8601
end
# Authority Counts
to_field 'author_variants_i' do |_record, accumulator|
  accumulator << author_variant_count
end
to_field 'subject_variants_i' do |_record, accumulator|
  accumulator << subject_variant_count
end
to_field 'geo_variants_i' do |_record, accumulator|
  accumulator << geo_variant_count
end
