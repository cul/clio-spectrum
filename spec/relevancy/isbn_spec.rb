require 'spec_helper'

describe 'ISBN Searching', :skip_travis do

  # Support fielded ISBN searches to hit on 020$z, "Canceled/invalid ISBN"
  # NEXT-1050 - Search for invalid ISBN
  # http://www.loc.gov/marc/bibliographic/bd020.html
  it 'should hit on "invalid" ISBNs', :skip_travis do
    isbn_z = '9789770274208'
    resp = solr_resp_doc_ids_only('q' => isbn_z)
    expect(resp.size).to be <= 2
    expect(rank(resp, 8682754)).to be <= 2
  end


  it 'should hit on 10- or 13-digit forms' do

    # bib 5441161, ISBN-10 9608733006, ISBN-13 9789608733008
    resp = solr_resp_doc_ids_only(q: '9608733006', search_field: 'isbn')
    expect(resp.size).to be <= 2
    expect(rank(resp, 5441161)).to be <= 2
    resp = solr_resp_doc_ids_only(q: '9789608733008', search_field: 'isbn')
    expect(resp.size).to be <= 2
    expect(rank(resp, 5441161)).to be <= 2

    # bib 5200467, ISBN-10 3487126141, ISBN-13 9783487126142
    resp = solr_resp_doc_ids_only(q: '3487126141', search_field: 'isbn')
    expect(resp.size).to be <= 2
    expect(rank(resp, 5200467)).to be <= 2
    resp = solr_resp_doc_ids_only(q: '9783487126142', search_field: 'isbn')
    expect(resp.size).to be <= 2
    expect(rank(resp, 5200467)).to be <= 2
  end


  # Searching by dash-delimited ISBN should work !!!

end


