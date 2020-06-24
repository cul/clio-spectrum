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

describe 'Testing Call Number Searching', :skip_travis do
  it 'Basic Call-Number, searching all-fields or call-number only' do
    resp = solr_resp_doc_ids_only('q' => 'AA966 B25 R11')

    expect(resp.size).to be <= 1
    expect(rank(resp, 814350)).to be <= 1

    resp = solr_resp_doc_ids_only('q' => '{!qf=location_call_number_txt pf=location_call_number_txt}AA966 B25 R11')

    expect(resp.size).to be <= 1
    expect(rank(resp, 814350)).to be <= 1
  end

  it 'Quoted Call-Number, searching all-fields or call-number only' do
    resp = solr_resp_doc_ids_only('q' => '"AA966 B25 R11"')

    expect(resp.size).to be <= 1
    expect(rank(resp, 814350)).to be <= 1

    resp = solr_resp_doc_ids_only('q' => '{!qf=location_call_number_txt pf=location_call_number_txt}"AA966 B25 R11"')

    expect(resp.size).to be <= 1
    expect(rank(resp, 814350)).to be <= 1
  end

  it 'Call-Number first token, searching all-fields or call-number only' do
    resp = solr_resp_doc_ids_only('q' => 'AA966')

    expect(resp.size).to be >= 600
    expect(resp.size).to be <= 700

    resp = solr_resp_doc_ids_only('q' => '{!qf=location_call_number_txt pf=location_call_number_txt}AA966')

    expect(resp.size).to be >= 600
    expect(resp.size).to be <= 700
  end

  it 'Quoted Call-Number first token, searching all-fields or call-number only' do
    resp = solr_resp_doc_ids_only('q' => '"AA966"')

    expect(resp.size).to be >= 600
    expect(resp.size).to be <= 700

    resp = solr_resp_doc_ids_only('q' => '{!qf=location_call_number_txt pf=location_call_number_txt}"AA966"')

    expect(resp.size).to be >= 600
    expect(resp.size).to be <= 700
  end

  it 'Zine Call-Number searching' do
    resp = solr_resp_doc_ids_only('q' => '{!qf=location_call_number_txt pf=location_call_number_txt}Zines')

    expect(resp.size).to be >= 5000
    expect(resp.size).to be <= 6000

    resp = solr_resp_doc_ids_only('q' => 'Zines W474o')

    expect(resp.size).to be <= 1
    expect(rank(resp, 7684507)).to be <= 1

    resp = solr_resp_doc_ids_only('q' => '{!qf=location_call_number_txt pf=location_call_number_txt}Zines W474o')

    expect(resp.size).to be <= 1
    expect(rank(resp, 7684507)).to be <= 1
  end
end
