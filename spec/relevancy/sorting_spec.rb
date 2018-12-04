require 'spec_helper'

describe 'Solr sort order', :skip_travis do
  # NEXT-962 - Would it be possible for CLIO catalog A-Z to sort by word
  it "should alpha-sort 'asia' before 'asian'" do
    # resp = solr_resp_ids_from_query('asia* 965hrportal')
    resp = solr_resp_doc_ids_only('q' => 'asia* 965hrportal', 'sort' => 'title_sort asc')

    # The bib for "Asia Pacific Forum" should be before
    # any of the "Asian ..." records
    rank7038675 = rank(resp, 7038675)
    expect(rank(resp, 7038673)).to be > rank7038675
    expect(rank(resp, 7886427)).to be > rank7038675
    expect(rank(resp, 7038672)).to be > rank7038675
    expect(rank(resp, 7038674)).to be > rank7038675
    expect(rank(resp, 7038747)).to be > rank7038675
  end
end
