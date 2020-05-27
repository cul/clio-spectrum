require 'spec_helper'

# NEXT-824 - Apostrophe character
# Variations in character used in place of simple apostophe should all work
describe 'Apostrophe-like character searching', :skip_travis do
  characterList = [
    "\x27",          # APOSTROPHE
    "\xCA\xBC",      # MODIFIER LETTER APOSTROPHE
    "\xCA\xB9",      # MODIFIER LETTER PRIME
    "\xCA\xBE",      # MODIFIER LETTER RIGHT HALF RING
    "\xCA\xBF",      # MODIFIER LETTER LEFT HALF RING
    # 5/2014 - yet another possibility, bib 2754188,
    # ticket NEXT-1066 (Series link does not retrieve...)
    "\xCA\xBB", # MODIFIER LETTER TURNED COMMA
    # this fails!  WDF doesn't treat it like the others.
    # So far, we have no example MARC records which use this, and no
    # requests to support it, so leave it as is.
    # If we need to, we can use special rules in schema to remap.
    # "\xE2\x80\x99",  # RIGHT SINGLE QUOTATION MARK
  ]

  it 'should work equivalently for all forms, unquoted' do
    characterList.each do |lookalike|
      # puts "unquoted lookalike=[#{lookalike}]"
      query = "Qur#{lookalike}anic and non-Qur#{lookalike}anic Islam"
      resp = solr_resp_doc_ids_only('q' => query)
      expect(rank(resp, 2043563)).to be < 10
    end
  end

  it 'should work equivalently for all forms, quoted' do
    characterList.each do |lookalike|
      # puts "quoted lookalike=[#{lookalike}]"
      query = "Qur#{lookalike}anic and non-Qur#{lookalike}anic Islam"
      resp = solr_resp_doc_ids_only('q' => '"' + query + '"')
      expect(rank(resp, 2043563)).to be < 10
    end
  end
end

# NEXT-1036 - Quoted Subject search fails
# bib 2354899 is "Pennsylvania Station (New York, N.Y.)", an exact match
# bibs 3460633 and 3460619 are a near match that should be returned,
#                "Pennsylvania Railroad Station (New York, N.Y.)"
# 7/21/2008 - UPDATE - Catalogers have corrected 3460633 and 3460619,
# they are now the same as 2354899.  Update expectations accordingly.
# We have no other exmples of near-misses - we're not really testing
# proper quote handling any longer here.
describe 'Searching of N.Y. Subject Strings', :skip_travis do
  baseTerm = 'Pennsylvania Station New York,'

  it 'should work for:  N.Y., unquoted' do
    resp = solr_resp_doc_ids_only(subject_search_args("#{baseTerm} N.Y."))
    expect(resp.size).to be >= 15
    expect(rank(resp, 2354899)).to be <= 5
    expect(rank(resp, 3460633)).to be <= 50
    expect(rank(resp, 3460619)).to be <= 50
  end

  it 'should work for:  N. Y., unquoted' do
    resp = solr_resp_doc_ids_only(subject_search_args("#{baseTerm} N. Y."))
    expect(resp.size).to be >= 15
    expect(rank(resp, 2354899)).to be <= 5
    expect(rank(resp, 3460633)).to be <= 50
    expect(rank(resp, 3460619)).to be <= 50
  end

  it 'should work for:  NY, unquoted' do
    resp = solr_resp_doc_ids_only(subject_search_args("#{baseTerm} NY"))
    expect(resp.size).to be >= 15
    expect(rank(resp, 2354899)).to be <= 5
    expect(rank(resp, 3460633)).to be <= 50
    expect(rank(resp, 3460619)).to be <= 50
  end

  it 'should work for:  N Y, unquoted' do
    resp = solr_resp_doc_ids_only(subject_search_args("#{baseTerm} N Y"))
    expect(resp.size).to be >= 15
    expect(rank(resp, 2354899)).to be <= 5
    expect(rank(resp, 3460633)).to be <= 50
    expect(rank(resp, 3460619)).to be <= 50
  end

  it 'should work for:  N. Y., quoted' do
    resp = solr_resp_doc_ids_only(subject_search_args("\"#{baseTerm} N. Y.\""))
    expect(resp.size).to be >= 15
    expect(rank(resp, 2354899)).to be <= 5
    expect(rank(resp, 3460633)).to be <= 50
    expect(rank(resp, 3460619)).to be <= 50
  end
end

# NEXT-998 - single-quote within double-quotes
describe 'Variants of query: "if i can\'t dance" revolution', :skip_travis do
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
      expect(rank(resp, 9560671)).to be == 1
    end
  end
end

# NEXT-999 - single-quote within double-quotes
describe 'NEXT-999: Queries with embedded single-quotes', :skip_travis do
  query = "Memoires de l'association francaise d'archeologie merovingienne"
  it "should have >=5 hits for unquoted #{query}" do
    resp = solr_resp_doc_ids_only('q' => query)
    expect(resp.size).to be >= 5
  end
  it "should have >=5 hits for quoted #{query}" do
    resp = solr_resp_doc_ids_only('q' => '"' + query + '"')
    expect(resp.size).to be >= 5
  end
end

# NEXT-1023 - single-quote within double-quotes
describe 'NEXT-1023: Queries with embedded single-quotes', :skip_travis do
  query = "storia dell'urbanistica"
  it "should have >50 hits for unquoted #{query}" do
    resp = solr_resp_doc_ids_only('q' => query)
    expect(resp.size).to be >= 50
  end
  it "should have >50 hits for quoted #{query}" do
    resp = solr_resp_doc_ids_only('q' => '"' + query + '"')
    expect(resp.size).to be >= 50
  end
end

# NEXT-1034 - single-quote within double-quotes
describe 'NEXT-1034: Queries with embedded single-quotes', :skip_travis do
  query = "dictionnaire de l'ameublement"

  it "should work for unquoted #{query}" do
    resp = solr_resp_doc_ids_only('q' => query)
    expect(rank(resp, 3108332)).to be <= 10
  end
  it "should work for quoted #{query}" do
    resp = solr_resp_doc_ids_only('q' => '"' + query + '"')
    expect(rank(resp, 3108332)).to be <= 10
  end
end
