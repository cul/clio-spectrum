# To have access to various built-in logic
# for pulling things out of MARC21, like `marc_languages`
require 'traject/macros/marc21_semantics'
extend  Traject::Macros::Marc21Semantics

# To have access to the traject marc format/carrier classifier
require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats

to_field "id", extract_marc("001", :first => true)

to_field "marc_display", serialized_marc(:format => "xml")

to_field "text", extract_all_marc_values

to_field "author_t", extract_marc("100abcdgqu:110abcdgnu:111acdegjnqu")

to_field "author_variant_t", extract_marc("400abcdgqu:410abcdgnu:411acdegjnqu")


