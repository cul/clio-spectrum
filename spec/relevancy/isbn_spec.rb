require 'spec_helper'

describe 'ISBN Searching' do

  # Support fielded ISBN searches to hit on 020$z, "Canceled/invalid ISBN"
  # NEXT-1050 - Search for invalid ISBN
  # http://www.loc.gov/marc/bibliographic/bd020.html
  it 'should hit on "invalid" ISBNs' do
    isbn_z = '9789770274208'
    resp = solr_resp_doc_ids_only('q' => isbn_z)
    
    

    expect(resp.size).to eq 1
    expect(rank(resp, 8682754)).to be == 1
  end



  # Searching by dash-delimited ISBN should work !!!




end


