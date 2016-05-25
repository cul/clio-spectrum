# To have access to various built-in logic
# for pulling things out of MARC21, like `marc_languages`
require 'traject/macros/marc21_semantics'
extend  Traject::Macros::Marc21Semantics

# To have access to the traject marc format/carrier classifier
require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats

Marc21 = Traject::Macros::Marc21 # shortcut

# Any fields with any of these subfields should be ignored for 
# our purposes.  (Subdivisions, Title, etc.)
disqualifying_subfields = ['k', 't', 'v', 'x', 'y', 'z']

# Don't process records we're not interested in.
# For now only:
# - Name Authority records, but not qualified Name records
# - Subject Authority Records, only Topical Term, unqualified
# - And skip if there are no variants
each_record do |record, context|
  # # abort after a certain number of records
  # raise "EARLY ABORT FOR TESTING" if context.position > 1000

  interesting_fields = [ '100', '110', '111', '150']
  # for faster testing of subset...
  # interesting_fields = ['100']

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


  if skip
    note = name.nil? ? '(no authorized name field)' : "(\"#{name}\")"
    context.skip!("skipping auth id #{record['001'].value} #{note}")
    next
  end

end



to_field "id", extract_marc("001", :first => true)

to_field "marc_display", serialized_marc(:format => "xml")

to_field "text", extract_all_marc_values

to_field "author_t", extract_marc("100abcdgqu:110abcdgnu:111acdegjnqu", trim_punctuation: false)

to_field "author_variant_t", extract_marc("400abcdq:410abcd:411acde:500abcdq:510abcd:511acde", trim_punctuation: false)

to_field "subject_t", extract_marc("150a", trim_punctuation: false)

# to_field "subject_variant_t", extract_marc("450a:550a", trim_punctuation: false)
to_field "subject_variant_t" do |record, accumulator, context|
  record.fields(['450','550']).each do |field|
    next unless field['a']

    # Check all the subfields of this field...
    all_subfields = field.subfields.map{ |subfield| subfield.code }
    # ... against the "disqualifying" list.  (intersection must be empty)
    next unless (all_subfields & disqualifying_subfields).empty?

    # ok, there's a "a", and no bad subfields, so yes, we want this variant...
    accumulator << field['a']
  end
end



