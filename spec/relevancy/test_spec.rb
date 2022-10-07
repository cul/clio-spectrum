require 'spec_helper'

describe 'Testing rsolr-rspec support', :skip_travis do
  it "q of 'Buddhism' should get many, many results" do
    resp = solr_resp_doc_ids_only('q' => 'Buddhism')

    expect(resp.size).to be > 20000
    expect(resp.size).to be < 50000
  end

  # utility, for spitting out the bib keys that match a given query
  #   it "BIB LIST", focus: true do
  #     resp = solr_resp_doc_ids_only('q' => 'composers forum', 'search_field' => 'title', rows: 100)
  # puts    resp.inspect
  #   end
end
