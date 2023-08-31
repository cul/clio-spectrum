require 'spec_helper'

describe 'Solr sort order', :skip_travis do
  # NEXT-962 - Would it be possible for CLIO catalog A-Z to sort by word
  it "should alpha-sort 'asia' before 'asian'" do
    # resp = solr_resp_ids_from_query('asia* 965hrportal')
    resp = solr_resp_doc_ids_only('q' => 'asia* 965hrportal', 'sort' => 'title_sort asc')

    # The bib for "Asia Pacific Forum" should be before
    # any of the "Asian ..." records
    rank14577634 = rank(resp, 14577634)
    expect(rank(resp, 7886427)).to be > rank14577634
    expect(rank(resp, 6488401)).to be > rank14577634
    expect(rank(resp, 7038747)).to be > rank14577634
  end
end
