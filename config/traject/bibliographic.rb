# To have accumulatoress to various built-in logic
# for pulling things out of MARC21, like `marc_languages`
require 'traject/macros/marc21_semantics'
extend  Traject::Macros::Marc21Semantics

# To have accumulatoress to the traject marc format/carrier classifier
require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats

# require 'traject/macros/marc21'
# extend  Traject::Macros::Marc21
require 'traject/indexer'
require 'traject/macros/marc21'

require 'traject_utility'

Marc21 = Traject::Macros::Marc21 # shortcut

bibs = 0
lookups = 0

ATOZ = ('a'..'z').to_a.join('')

to_field "id", extract_marc("001", first: true)

to_field "marc_display", serialized_marc(:format => "xml")

# This calculates a single timestamp and applies it to all records
# to_field "marc_dt", literal(Time.now.utc.iso8601)
# This calculates a timestamp for each record as it is processed
to_field "marc_dt" do |record, accumulator|
   accumulator << Time.now.utc.iso8601
end


to_field "text", extract_all_marc_values(from: '050', to: '966')

to_field "author_txt", extract_marc("100abcegqu:110abcdegnu:111acdegjnqu", trim_punctuation: false)
to_field "author_addl_txt", extract_marc("700abcegqu:710abcdegnu:711acdegjnqu", trim_punctuation: false)
to_field "author_facet", extract_marc("100abcdq:110#{ATOZ}:111#{ATOZ}:700abcdq:710#{ATOZ}:711#{ATOZ}", trim_punctuation: true, alternate_script: false)
to_field "author_display", extract_marc("100abcdq:110#{ATOZ}:111#{ATOZ}", trim_punctuation: true, alternate_script: false)
to_field "author_vern_display", extract_marc("100abcdq:110#{ATOZ}:111#{ATOZ}", trim_punctuation: true, alternate_script: :only)
to_field "author_sort", marc_sortable_author

# ### authority variants are not inserted at original index time ###
# authorities_solr = RSolr.connect(url: APP_CONFIG['authorities_solr_url'])
# puts_and_log("authorities_solr=#{authorities_solr}")
# to_field "author_variants_txt" do |record, accumulator|
#   bibs = bibs + 1
#   id = Traject::Macros::Marc21.extract_marc_from(record, "001", first: true)
#   author = ::Traject::Macros::Marc21.extract_marc_from(record, "100abcegqu:110abcdegnu:111acdegjnqu", :trim_punctuation => true, alternate_script: false, first: true).first
#   # next
#   if author.present?
#     # Lookup each authorized heading against authorities, retrieve variants
#     response = authorities_solr.get 'select', params: {fq: "author_t:#{CGI.escape author}", fl: 'author_variant_t', rows: 1, qt: 'select'}
#     lookups = lookups + 1
#     # puts response.inspect
#     if response["response"]["docs"].size > 0
#       variants = response["response"]["docs"].first['author_variant_t']
#       if variants && variants.size > 0
#         puts_and_log("(#{id.first}) author [#{author}] ==> variants [#{variants.join(' / ')}]", :debug)
#         accumulator << variants
#         puts "total bibs #{bibs} / lookups #{lookups}"
#       end
#     end
#   end
# end


to_field "title_txt", extract_marc("245afknp", trim_punctuation: false, alternate_script: true)
to_field "title_display", extract_marc("245abfhknp", trim_punctuation: true, alternate_script: false)
to_field "title_vern_display", extract_marc("245abfhknp", trim_punctuation: true, alternate_script: :only)
to_field "title_filing_txt", extract_marc_filing_version("245a")
to_field "title_filing_full_txt", extract_marc_filing_version("245ab")
to_field "subtitle_txt", extract_marc("245b", trim_punctuation: true, alternate_script: true)
to_field "title_first_facet", marc_sortable_title do |record, accumulator|
  accumulator.map!{ |title|
    if title.strip.first.match(/\d/)
      '0-9'
    else
      title.strip.first.upcase
    end
    }
end
to_field "title_addl_txt", extract_marc("245abnps:130#{ATOZ}:240abcdefgklmnopqrs:210ab:222ab:242abnp:243abcdefgklmnopqrs:246abcdefgnp:247abcdefgnp:780#{ATOZ}:785#{ATOZ}:700gklmnoprst:710fgklmnopqrst:711fgklnpst:730abcdefgklmnopqrst:740anp", trim_punctuation: false, alternate_script: true)
to_field "title_series_txt", extract_marc("830#{ATOZ}", trim_punctuation: true, alternate_script: true)
to_field "title_series_display", extract_marc("830#{ATOZ}", trim_punctuation: true, alternate_script: false)
to_field "title_sort", marc_sortable_title do |record, accumulator|
  accumulator.map!{|title| title.strip.gsub(/[^[:word:]\s]/, '').downcase}
end


to_field "subject_txt", extract_marc("600#{ATOZ}:610#{ATOZ}:611#{ATOZ}:630#{ATOZ}:650#{ATOZ}:651#{ATOZ}:653aa:654#{ATOZ}:655#{ATOZ}", trim_punctuation: true, alternate_script: true)
to_field "subject_topic_facet", extract_marc("600abcdq:600x:610ab:610x:611ab:611x:630a:630x:650a:650x:651x:655x", trim_punctuation: true, alternate_script: false)
to_field "subject_era_facet", extract_marc("600y:610y:611y:630y:650y:651y:655y", trim_punctuation: true, alternate_script: false)
to_field "subject_geo_facet", extract_marc("600z:610z:611z:630z:650z:651a:651z:655z", trim_punctuation: true, alternate_script: false)
to_field "subject_form_facet", extract_marc("600v:610v:611v:630v:650v:651v:655ab:655v", trim_punctuation: true, alternate_script: false)
to_field "subject_form_txt", extract_marc("600v:610v:611v:630v:650v:651v:655ab:655v", trim_punctuation: true, alternate_script: false)

# 781z - geographic subfield divisions, need the value as query into authorities solr
to_field "geo_subdivision_txt", extract_marc("600zz:610zz:611zz:630zz:650zz:651zz:655zz", trim_punctuation: true)

to_field "pub_place_display", extract_marc("260a:264a", trim_punctuation: true, alternate_script: false)
to_field "pub_name_display", extract_marc("260b:264b", trim_punctuation: true, alternate_script: false)
to_field "pub_year_display", extract_marc("260c:264c", trim_punctuation: true, alternate_script: false)
to_field "pub_place_txt", extract_marc("260a:264a", trim_punctuation: true, alternate_script: false)
to_field "pub_name_txt", extract_marc("260b:264b", trim_punctuation: true, alternate_script: false)
to_field "pub_year_txt", extract_marc("260c:264c", trim_punctuation: true, alternate_script: false)

to_field "pub_date_txt", marc_publication_date(estimate_tolerance: 100)

to_field "language_facet", extract_marc("008[35-37]:041a:041d", translation_map: 'language_map')

to_field "format", extract_marc("993a")

to_field "lc_1letter_facet", extract_marc("990a") do |record, accumulator|
  accumulator.map!{ |value|
    Traject::TranslationMap.new("callnumber_map")[value.first]
     }
end
to_field "lc_2letter_facet", extract_marc("990a", translation_map: 'callnumber_full_map')
to_field "lc_subclass_facet", extract_marc("990a", translation_map: 'callnumber_full_map')

to_field 'clio_id_display', extract_marc("001", trim_punctuation: true)

to_field 'acq_dt', extract_marc("997a", trim_punctuation: true)

to_field 'source_facet', extract_marc("995a", trim_punctuation: true)
to_field 'source_display', extract_marc("995a", trim_punctuation: true)

to_field 'repository_facet', extract_marc("996a", trim_punctuation: true)
to_field 'repository_display', extract_marc("996a", trim_punctuation: true)

to_field 'boost_exact', extract_marc("999a", trim_punctuation: true)

to_field 'database_restrictions_display', extract_marc("506a", trim_punctuation: false)
to_field 'database_discipline_facet', extract_marc("967a", translation_map: 'database_discipline_map')
to_field 'database_resource_type_facet', extract_marc("966a", translation_map: 'database_resource_type_map')

to_field 'summary_display', extract_marc("520#{ATOZ}", trim_punctuation: false)



# Searchable ISBN: consider both the 020a and 020z, as 10- or 13-digit
to_field 'isbn_txt', extract_marc('020az', :separator=>nil) do |record, accumulator|
     original = accumulator.dup
     accumulator.map!{|isbn| StdNum::ISBN.allNormalizedValues(isbn)}
     accumulator << original
     accumulator.flatten!
     accumulator.uniq!
end


# Displayed ISBN - only the primary 020a, cleaned but otherwise as-given
ISBN_CLEAN = /([\- \d]*[X\d])/
to_field "isbn_display", extract_marc("020a") do |record, accumulator|
  accumulator.map!{ |isbn|
    if clean_isbn = isbn.match(ISBN_CLEAN)
      clean_isbn[1]
    end
  }
end

ISSN_CLEAN = /(\d{4}-\d{3}[X\d])/

to_field "issn_txt", extract_marc("022a:022l:022y:775x:776x") do |record, accumulator|
  accumulator.map!{ |issn|
    if clean_issn = issn.match(ISSN_CLEAN)
      clean_issn[1]
    end
  }
end
to_field "issn_display", extract_marc("022a") do |record, accumulator|
  accumulator.map!{ |issn|
    if clean_issn = issn.match(ISSN_CLEAN)
      clean_issn[1]
    end
  }
end

to_field "lccn_display", extract_marc("010a", trim_punctuation: true)
to_field "lccn_txt", extract_marc("010a:010z", trim_punctuation: true)

OCLC_CLEAN = /^\(OCoLC\)[^0-9A-Za-z]*([0-9A-Za-z]*)[^0-9A-Za-z]*$/

to_field "oclc_txt", extract_marc("035a") do |record, accumulator|
  accumulator.map!{ |oclc|
    if clean_oclc = oclc.match(OCLC_CLEAN)
      clean_oclc[1]
    end
  }
end
to_field "oclc_display", extract_marc("035a") do |record, accumulator|
  accumulator.map!{ |oclc|
    if clean_oclc = oclc.match(OCLC_CLEAN)
      clean_oclc[1]
    end
  }
end

to_field "full_publisher_display", extract_marc("260#{ATOZ}:264#{ATOZ}", trim_punctuation: false, alternate_script: false)


LOCATION_CALL_NUMBER = /^(.*)\|DELIM\|.*/
CALL_NUMBER_ONLY = /^.* \>\> (.*)\|DELIM\|.*/

to_field "location_call_number_id_display", extract_marc("992b", trim_punctuation: true)
to_field "location_call_number_txt", extract_marc("992b", trim_punctuation: true) do |record, accumulator|
  accumulator.map!{ |value|
    if clean_value = value.match(LOCATION_CALL_NUMBER)
      clean_value[1]
    end
  }
end

to_field "call_number_txt", extract_marc("992b", trim_punctuation: true) do |record, accumulator|
  accumulator.map!{ |value|
    if clean_value = value.match(CALL_NUMBER_ONLY)
      clean_value[1]
    end
  }
end
to_field "call_number_display", extract_marc("992b", trim_punctuation: true) do |record, accumulator|
  accumulator.map!{ |value|
    if clean_value = value.match(CALL_NUMBER_ONLY)
      clean_value[1]
    end
  }
end

to_field "location_facet", extract_marc("992a", trim_punctuation: true)
to_field "location_txt", extract_marc("992b", trim_punctuation: true) do |record, accumulator|
  accumulator.map!{ |value|
    if clean_value = value.match(LOCATION_CALL_NUMBER)
      clean_value[1]
    end
  }
end

to_field "url_munged_display" do |record, accumulator|
  record.fields('856').each { |field856|
    next unless field856.indicator1 == '4'
    accumulator << [ field856.indicator2, field856['3'], field856['u'], field856['z'] ].join('|||')
  }
end


# Shelf Browse support fields

to_field "shelfkey" do |record, accumulator|
  id = Marc21.extract_marc_from(record, "001", first: true).first
  record.fields('991').each { |field991|
    next unless field991 && field991['b']
    accumulator << "#{field991['b'].downcase}+#{id}"
  }
end
to_field "reverse_shelfkey" do |record, accumulator|
  id = Marc21.extract_marc_from(record, "001", first: true).first
  record.fields('991').each { |field991|
    next unless field991 && field991['b']
    accumulator << TrajectUtility.reverseString("#{field991['b'].downcase}+#{id}")
  }
end

to_field "item_display" do |record, accumulator|
  id = Marc21.extract_marc_from(record, "001", first: true).first
  record.fields('991').each { |field991|
    next unless field991 && field991['a'] && field991['b']
    display_call_number = field991['a']
    shelfkey = "#{field991['b'].downcase}+#{id}"
    reverse_shelfkey = TrajectUtility.reverseString("#{field991['b'].downcase}+#{id}")
    accumulator << display_call_number + " | " + shelfkey + " | " + reverse_shelfkey
  }
end







