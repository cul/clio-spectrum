require 'spec_helper'

# Use some examples from
#   NEXT-36 - Search by a call number range.
#   NEXT-241 - Staff need to be able to search for a specific call number
#
# AA966 B25 R11
# "AA966 B25 R11"
# AA966
# AA966*
#
# In addition, the following two used to work but do not any longer.
# Does anybody care?
#   AA966B25R11
#   "AA966B25R11"

describe 'Testing Call Number Searching' do

  it 'Basic Call-Number, searching all-fields or call-number only' do
    resp = solr_resp_doc_ids_only('q' => 'AA966 B25 R11')
    resp.should have_at_most(1).documents
    resp.should include('814350').in_first(1).results

    resp = solr_resp_doc_ids_only('q' => '{!qf=location_call_number_txt pf=location_call_number_txt}AA966 B25 R11')
    resp.should have_at_most(1).documents
    resp.should include('814350').in_first(1).results
  end

  it 'Quoted Call-Number, searching all-fields or call-number only' do
    resp = solr_resp_doc_ids_only('q' => '"AA966 B25 R11"')
    resp.should have_at_most(1).documents
    resp.should include('814350').in_first(1).results

    resp = solr_resp_doc_ids_only('q' => '{!qf=location_call_number_txt pf=location_call_number_txt}"AA966 B25 R11"')
    resp.should have_at_most(1).documents
    resp.should include('814350').in_first(1).results
  end

  it 'Call-Number first token, searching all-fields or call-number only' do
    resp = solr_resp_doc_ids_only('q' => 'AA966')
    resp.should have_at_least(600).documents
    resp.should have_at_most(700).documents

    resp = solr_resp_doc_ids_only('q' => '{!qf=location_call_number_txt pf=location_call_number_txt}AA966')
    resp.should have_at_least(600).documents
    resp.should have_at_most(700).documents
  end

  it 'Quoted Call-Number first token, searching all-fields or call-number only' do
    resp = solr_resp_doc_ids_only('q' => '"AA966"')
    resp.should have_at_least(600).documents
    resp.should have_at_most(700).documents

    resp = solr_resp_doc_ids_only('q' => '{!qf=location_call_number_txt pf=location_call_number_txt}"AA966"')
    resp.should have_at_least(600).documents
    resp.should have_at_most(700).documents
  end

  it 'Zine Call-Number searching' do
    resp = solr_resp_doc_ids_only('q' => '{!qf=location_call_number_txt pf=location_call_number_txt}Zines')
    resp.should have_at_least(3400).documents
    resp.should have_at_most(4000).documents

    resp = solr_resp_doc_ids_only('q' => 'Zines W474o')
    resp.should have_at_most(1).documents
    resp.should include('7684507').in_first(1).results

    resp = solr_resp_doc_ids_only('q' => '{!qf=location_call_number_txt pf=location_call_number_txt}Zines W474o')
    resp.should have_at_most(1).documents
    resp.should include('7684507').in_first(1).results
  end

end
