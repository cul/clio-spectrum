require 'spec_helper'

describe 'Testing rsolr-rspec support' do

  it "q of 'Buddhism' should get around 18,000 results" do
    resp = solr_resp_doc_ids_only('q' => 'Buddhism')
    resp.should have_at_least(18_000).documents
    resp.should have_at_most(22_000).documents
  end

# utility, for spitting out the bib keys that match a given query
#   it "BIB LIST", focus: true do
#     resp = solr_resp_doc_ids_only('q' => 'composers forum', 'search_field' => 'title', rows: 100)
# puts    resp.inspect
#   end

end
