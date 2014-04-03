require 'spec_helper'


# NEXT-824 - Apostrophe character
# Variations in character used in place of simple apostophe should all work
describe "Apostrophe-like character searching" do
  characterList = [
    "\x27",          # APOSTROPHE
    "\xCA\xBC",      # MODIFIER LETTER APOSTROPHE
    "\xCA\xB9",      # MODIFIER LETTER PRIME
    "\xCA\xBE",      # MODIFIER LETTER RIGHT HALF RING
    "\xCA\xBF",      # MODIFIER LETTER LEFT HALF RING
    # this fails!  WDF doesn't treat it like the others.
    # So far, we have no example MARC records which use this, and no
    # requests to support it, so leave it as is.
    # If we need to, we can use special rules in schema to remap.
    # "\xE2\x80\x99",  # RIGHT SINGLE QUOTATION MARK  
    ]

    it "should work equivalently for all forms, unquoted" do
      characterList.each do | lookalike |
        # puts "unquoted lookalike=[#{lookalike}]"
        query = "Qur#{lookalike}anic and non-Qur#{lookalike}anic Islam"
        resp = solr_resp_doc_ids_only('q' => query)
        resp.should include('2043563')
      end
    end

  it "should work equivalently for all forms, quoted" do
    characterList.each do | lookalike |
      # puts "quoted lookalike=[#{lookalike}]"
      query = "Qur#{lookalike}anic and non-Qur#{lookalike}anic Islam"
      resp = solr_resp_doc_ids_only('q' => '"' + query + '"')
      resp.should include('2043563')
    end
  end
end


# NEXT-1036 - Quoted Subject search fails
# bib 2354899 is "Pennsylvania Station (New York, N.Y.)", an exact match
# bibs 3460633 and 3460619 are a near match that should be returned,
#   "Pennsylvania Railroad Station (New York, N.Y.)"
describe 'Searching of N.Y. Subject Strings' do
  baseTerm = 'Pennsylvania Station New York,'

  it "should work for:  N.Y., unquoted" do
    resp = solr_resp_doc_ids_only( subject_search_args("#{baseTerm} N.Y.") )
    resp.should have_at_least(15).documents
    resp.should include('2354899').in_first(3).results
    resp.should include('3460633')
    resp.should include('3460619')
  end

  it "should work for:  N. Y., unquoted" do
    resp = solr_resp_doc_ids_only( subject_search_args("#{baseTerm} N. Y.") )
    resp.should have_at_least(15).documents
    resp.should include('2354899').in_first(3).results
    resp.should include('3460633')
    resp.should include('3460619')
  end

  it "should work for:  NY, unquoted" do
    resp = solr_resp_doc_ids_only( subject_search_args("#{baseTerm} NY") )
    resp.should have_at_least(15).documents
    resp.should include('2354899').in_first(3).results
    resp.should include('3460633')
    resp.should include('3460619')
  end

  it "should work for:  N Y, unquoted" do
    resp = solr_resp_doc_ids_only( subject_search_args("#{baseTerm} N Y") )
    resp.should have_at_least(15).documents
    resp.should include('2354899').in_first(3).results
    resp.should include('3460633')
    resp.should include('3460619')
  end

  it "should work for:  N.Y., quoted" do
    resp = solr_resp_doc_ids_only( subject_search_args("\"#{baseTerm} N.Y.\"") )
    resp.should have_at_least(15).documents
    resp.should include('2354899').in_first(3).results
    resp.should_not include('3460633')
    resp.should_not include('3460619')
  end

  it "should work for:  N. Y., quoted" do
    resp = solr_resp_doc_ids_only( subject_search_args("\"#{baseTerm} N. Y.\"") )
    resp.should have_at_least(15).documents
    resp.should include('2354899').in_first(3).results
    resp.should_not include('3460633')
    resp.should_not include('3460619')
  end

end


# NEXT-998 - single-quote within double-quotes
describe 'Variants of query: "if i can\'t dance" revolution' do
  variants = [
    '"if i can\'t dance" revolution',
    '"if i can\'t dance " revolution',
    '"i can\'t dance" revolution',
    '"can\'t dance" revolution',
    '"if i" can\'t dance revolution',
    'if i cant dance revolution'
    ]

  variants.each do |variant|
    it "should work for: #{variant}" do
      resp = solr_resp_doc_ids_only('q' => variant)
      resp.should include('9560671').in_first(1).results
    end
  end

end


# NEXT-999 - single-quote within double-quotes
describe 'NEXT-999: Queries with embedded single-quotes' do
  query = "Memoires de l'association francaise d'archeologie merovingienne"
  it "should have >=5 hits for unquoted #{query}" do
    resp = solr_resp_doc_ids_only('q' => query)
    resp.should have_at_least(5).documents
  end
  it "should have >=5 hits for quoted #{query}" do
    resp = solr_resp_doc_ids_only('q' => '"' + query + '"')
    resp.should have_at_least(5).documents
  end
end


# NEXT-1023 - single-quote within double-quotes
describe 'NEXT-1023: Queries with embedded single-quotes' do
  query = "storia dell'urbanistica"
  it "should have >50 hits for unquoted #{query}" do
    resp = solr_resp_doc_ids_only('q' => query)
    resp.should have_at_least(50).documents
  end
  it "should have >50 hits for quoted #{query}" do
    resp = solr_resp_doc_ids_only('q' => '"' + query + '"')
    resp.should have_at_least(50).documents
  end
end


# NEXT-1034 - single-quote within double-quotes
describe 'NEXT-1034: Queries with embedded single-quotes' do
  query = "dictionnaire de l'ameublement"

  it "should work for unquoted #{query}" do
    resp = solr_resp_doc_ids_only('q' => query)
    resp.should include('3108332')
  end
  it "should work for quoted #{query}" do
    resp = solr_resp_doc_ids_only('q' => '"' + query + '"')
    resp.should include('3108332')
  end
end




