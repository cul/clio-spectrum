require 'spec_helper'


describe 'Testing rsolr-rspec support' do


  it "q of 'Buddhism' should get around 18,000 results" do
    resp = solr_resp_doc_ids_only({'q'=>'Buddhism'})
    resp.should have_at_least(17000).documents
    resp.should have_at_most(19000).documents
  end



end