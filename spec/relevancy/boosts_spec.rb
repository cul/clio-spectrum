require 'spec_helper'

# NEXT-950 - Boosts: A librarian can 'promote' resources
describe 'Boosts' do

  it "CLIO" do
    resp = solr_resp_doc_ids_only('q' => 'clio')
    resp.should include('2044498').in_first(1).results
  end

  it "dissertation(s)" do
    resp = solr_resp_doc_ids_only('q' => 'dissertation')
    resp.should include('2554991').in_first(1).results

    resp = solr_resp_doc_ids_only('q' => 'dissertations')
    resp.should include('2554991').in_first(1).results
  end

  it "ancestry" do
    resp = solr_resp_doc_ids_only('q' => 'ancestry')
    resp.should include('4173061').in_first(1).results
  end

  it "lexis nexis" do
    resp = solr_resp_doc_ids_only('q' => 'lexis nexis')
    resp.should include('2100385').in_first(1).results

    resp = solr_resp_doc_ids_only('q' => 'lexisnexis')
    resp.should include('2100385').in_first(1).results

    resp = solr_resp_doc_ids_only('q' => 'lexis')
    resp.should include('2100385').in_first(1).results
  end

  it "foundation center" do
    resp = solr_resp_doc_ids_only('q' => 'foundation center')
    resp.should include('3328966').in_first(1).results
  end

  it "foreign affairs" do
    resp = solr_resp_doc_ids_only('q' => 'foreign affairs')
    resp.should include('3326026').in_first(1).results
  end

  it "morningstar" do
    resp = solr_resp_doc_ids_only('q' => 'morningstar')
    resp.should include('9549367').in_first(1).results
  end

  it "wall street journal" do
    resp = solr_resp_doc_ids_only('q' => 'wall street journal')
    resp.should include('3385614').in_first(1).results
  end

  it "science" do
    resp = solr_resp_doc_ids_only('q' => 'science')
    resp.should include('3328066').in_first(1).results
  end

  it "the new yorker" do
    resp = solr_resp_doc_ids_only('q' => 'the new yorker')
    resp.should include('3327567').in_first(1).results
  end

  it "thomson" do
    resp = solr_resp_doc_ids_only('q' => 'thomson')
    resp.should include('5410648').in_first(1).results
  end

  it "naxos" do
    resp = solr_resp_doc_ids_only('q' => 'naxos')
    resp.should include('4793226').in_first(3).results
    resp.should include('8407612').in_first(3).results
    resp.should include('5517003').in_first(3).results
  end

  it "consumer reports" do
    resp = solr_resp_doc_ids_only('q' => 'consumer reports')
    resp.should include('3325559').in_first(1).results
  end

  it "harvard business review" do
    resp = solr_resp_doc_ids_only('q' => 'harvard business review')
    resp.should include('4813595').in_first(1).results
  end

  it "web of knowledge" do
    resp = solr_resp_doc_ids_only('q' => 'web of knowledge')
    resp.should include('10620670').in_first(2).results
    resp.should include('2054244').in_first(2).results
  end

  it "the economist" do
    resp = solr_resp_doc_ids_only('q' => 'the economist')
    resp.should include('3325775').in_first(1).results
  end

  it "caim" do
    resp = solr_resp_doc_ids_only('q' => 'caim')
    resp.should include('9463370').in_first(1).results
  end

  it "rilm" do
    resp = solr_resp_doc_ids_only('q' => 'rilm')
    resp.should include('2710784').in_first(1).results
  end

  it "gartner" do
    resp = solr_resp_doc_ids_only('q' => 'gartner')
    resp.should include('4759811').in_first(1).results
  end

end
