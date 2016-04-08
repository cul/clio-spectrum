# To have access to various built-in logic
# for pulling things out of MARC21, like `marc_languages`
require 'traject/macros/marc21_semantics'
extend  Traject::Macros::Marc21Semantics

# To have access to the traject marc format/carrier classifier
require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats

Marc21 = Traject::Macros::Marc21 # shortcut

# Don't process records we're not interested in.
# For now only:
# - Name Authority records, but not qualified Name records
# - Subject Authority Records, only Topical Term, unqualified
# - And skip if there are no variants
each_record do |record, context|
  # # abort after a certain number of records
  # raise "EARLY ABORT FOR TESTING" if context.position > 1000

  # interesting_fields = [ '100', '110', '111', '150']
  interesting_fields = ['150']
  disqualifying_subfields = ['k', 't', 'v', 'x', 'y', 'z']

  # assume we're going to skip this record, unless we find something interesting.
  skip = true
  name = nil

  interesting_fields.each { |field|
    # determine the tracings from the field tag
    see_from = field.sub(/^1/, '4')
    see_also = field.sub(/^1/, '5')

    # Is one of the heading fields in the record?
    if record[field].present?
      # ... with a name subfield ($a)?
      if record[field]['a'].present?
        name = record[field]['a']
        # ... and without further qualification (subdivision, subheading)?
        all_subfields = record[field].subfields.map{ |subfield| subfield.code }
        # (intersection must be empty)
        if (all_subfields & disqualifying_subfields).empty?
          # ... and there is also some kind of variant form present?
          if record[see_from].present? or record[see_also].present?
            # ... then KEEP THIS RECORD!
            puts "KEEP auth id #{record['001'].value} (\"#{name}\")"
            skip = false
          end
        end
      end
    end
  }

# skip = false if record['150'].present?

  if skip
    note = name.nil? ? '(no authorized name field)' : "(\"#{name}\")"
    context.skip!("skipping auth id #{record['001'].value} #{note}")
    next
  end
  # 
  # # But wait - also skip records that have no variants
  # see_also = 
  # unless record['400'].present? or record['500'].present?
  #   context.skip!("skipping, no variants (auth id #{record['001'].value})")
  #   next
  # end


  # # Skip records that aren't Name Authority records
  # unless record['100'].present?
  #   context.skip!("skipping non-name record (auth id #{record['001'].value})")
  #   next
  # end
  # 
  # unless record['100']['a'].present? or record['110']['a'].present? or record['111']['a'].present? or record['150']['a'].present?
  #   context.skip!("skipping, no auth heading found (auth id #{record['001'].value})")
  #   next
  # end

  # # Skip Name/Title Authority records
  # if record['100']['t'].present? or record['100']['k'].present? or
  #    record['110']['t'].present? or record['110']['k'].present? or
  #    record['111']['t'].present? or record['111']['k'].present?
  #   context.skip!("skipping name/title record (auth id #{record['001'].value})")
  #   next
  # end

# TODO - Subject Authorities
# including 100 fields with 008[14-15] set to "a" for appropriate use
# exclude based on all kinds of qualifying subfields:
# $v - Form subdivision (R)
# $x - General subdivision (R)
# $y - Chronological subdivision (R)
# $z - Geographic subdivision (R)
# docs:  https://www.loc.gov/marc/authority/ad100.html


end

# raise
to_field "id", extract_marc("001", :first => true)

to_field "marc_display", serialized_marc(:format => "xml")

to_field "text", extract_all_marc_values

to_field "author_t", extract_marc("100abcdgqu:110abcdgnu:111acdegjnqu", trim_punctuation: false)

to_field "author_variant_t", extract_marc("400abcdq:410abcd:411acde:500abcdq:510abcd:511acde", trim_punctuation: false)

to_field "subject_t", extract_marc("150a", trim_punctuation: false)

to_field "subject_variant_t", extract_marc("450a:550a", trim_punctuation: false)


