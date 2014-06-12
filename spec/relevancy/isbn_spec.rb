require 'spec_helper'

describe 'ISBN Searching' do

  # Support fielded ISBN searches to hit on 020$z, "Canceled/invalid ISBN"
  # NEXT-1050 - Search for invalid ISBN
  # http://www.loc.gov/marc/bibliographic/bd020.html
  it 'should hit on "invalid" ISBNs' do
    isbn_z = '9789770274208'
    resp = solr_resp_doc_ids_only('q' => isbn_z)
    resp.should have_at_most(1).documents
    resp.should include('8682754').in_first(1).results
  end

  # Searching by dash-delimited ISBN should work !!!

end


