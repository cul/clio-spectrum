require 'spec_helper'

# NEXT-950 - Boosts: A librarian can 'promote' resources
describe 'Boosts' do

  it "CLIO" do
    resp = solr_resp_doc_ids_only('q' => 'clio')
    expect(rank(resp, 2044498)).to be <= 1
  end

  it "dissertation(s)" do
    resp = solr_resp_doc_ids_only('q' => 'dissertation')
    expect(rank(resp, 2554991)).to be <= 1

    resp = solr_resp_doc_ids_only('q' => 'dissertations')
    expect(rank(resp, 2554991)).to be <= 1
  end

  it "ancestry" do
    resp = solr_resp_doc_ids_only('q' => 'ancestry')
    expect(rank(resp, 4173061)).to be <= 1
  end

  it "lexis nexis" do
    resp = solr_resp_doc_ids_only('q' => 'lexis nexis')
    expect(rank(resp, 2100385)).to be <= 1

    resp = solr_resp_doc_ids_only('q' => 'lexisnexis')
    expect(rank(resp, 2100385)).to be <= 1

    resp = solr_resp_doc_ids_only('q' => 'lexis')
    expect(rank(resp, 2100385)).to be <= 1
  end

  it "foundation center" do
    resp = solr_resp_doc_ids_only('q' => 'foundation center')
    expect(rank(resp, 3328966)).to be <= 1
  end

  it "foreign affairs" do
    resp = solr_resp_doc_ids_only('q' => 'foreign affairs')
    expect(rank(resp, 3326026)).to be <= 1
  end

  it "morningstar" do
    resp = solr_resp_doc_ids_only('q' => 'morningstar')
    expect(rank(resp, 10516547)).to be <= 1
  end

  it "wall street journal" do
    resp = solr_resp_doc_ids_only('q' => 'wall street journal')
    expect(rank(resp, 3385614)).to be <= 1
  end

  it "science" do
    resp = solr_resp_doc_ids_only('q' => 'science')
    expect(rank(resp, 3328066)).to be <= 1
  end

  it "the new yorker" do
    resp = solr_resp_doc_ids_only('q' => 'the new yorker')
    expect(rank(resp, 3327567)).to be <= 1
  end

  it "thomson" do
    resp = solr_resp_doc_ids_only('q' => 'thomson')
    expect(rank(resp, 5410648)).to be <= 1
  end

  it "naxos" do
    resp = solr_resp_doc_ids_only('q' => 'naxos')
    expect(rank(resp, 4793226)).to be <= 3
    expect(rank(resp, 8407612)).to be <= 3
    expect(rank(resp, 5517003)).to be <= 3
  end

  it "consumer reports" do
    resp = solr_resp_doc_ids_only('q' => 'consumer reports')
    expect(rank(resp, 3325559)).to be <= 1
  end

  it "harvard business review" do
    resp = solr_resp_doc_ids_only('q' => 'harvard business review')
    expect(rank(resp, 4813595)).to be <= 1
  end

  it "web of knowledge" do
    resp = solr_resp_doc_ids_only('q' => 'web of knowledge')
    expect(rank(resp, 10620670)).to be <= 2
    expect(rank(resp, 2054244)).to be <= 2
  end

  it "the economist" do
    resp = solr_resp_doc_ids_only('q' => 'the economist')
    expect(rank(resp, 3325775)).to be <= 1
  end

  it "cairn" do
    resp = solr_resp_doc_ids_only('q' => 'cairn')
    expect(rank(resp, 9463370)).to be <= 1
  end

  it "rilm" do
    resp = solr_resp_doc_ids_only('q' => 'rilm')
    expect(rank(resp, 11528023)).to be <= 1
  end

  it "gartner" do
    resp = solr_resp_doc_ids_only('q' => 'gartner')
    expect(rank(resp, 4759811)).to be <= 1
  end

end
