require 'spec_helper'


describe 'Solr sort order' do

  # NEXT-962 - Would it be possible for CLIO catalog A-Z to sort by word
  it "should alpha-sort 'asia' before 'asian'" do
    # resp = solr_resp_ids_from_query('asia* 965hrportal')
    resp = solr_resp_doc_ids_only({'q' => 'asia* 965hrportal', 'sort' => 'title_sort asc'})

    # The bib for "Asia Pacific Forum" should be before 
    # any of the "Asian ..." records
    resp.should include('7038675').before('7038673')
    resp.should include('7038675').before('7886427')
    resp.should include('7038675').before('7038672')
    resp.should include('7038675').before('7038674')
    resp.should include('7038675').before('7038747')
  end


end