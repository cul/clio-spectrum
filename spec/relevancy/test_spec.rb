require 'spec_helper'

describe 'Testing rsolr-rspec support' do

  it "q of 'Buddhism' should get around 18,000 results" do
    resp = solr_resp_doc_ids_only('q' => 'Buddhism')
    # resp.should have_at_least(17_000).documents
    # resp.should have_at_most(19_000).documents

    expect(resp.size).to be > 17_000
    expect(resp.size).to be < 19_000

  end

end
