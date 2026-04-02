require 'spec_helper'

# NEXT-330 - Single word journal titles continue to be a problem
#   mentions "Brain, Science, Lancet"
# NEXT-745 - Relevancy ranking clarification
#   mentions Lancet ("The Lancet"), Nation ("The Nation")
# NEXT-867 - The journal reproduction is not retrieved when searching for reproduction
# and also:  Gut, Nature, Heart, Science, Neurology, Circulation
describe 'Searching for one-word titles: ', :skip_travis do

  # LIBSYS-5286 - Journal "Reproduction" dropped out of CLIO
  # it 'Reproduction' do
  #   resp = solr_resp_ids_from_query('Reproduction')
  #   # expect(resp.get_first_doc_index({"id" => "4843265"})).to be < 1
  #   # expect(resp.has_document?({"id" => "4843265"}) ).to eq true
  #   # puts "RANK:" + rank(resp, 48432659).to_s
  #   # expect(resp.get_first_doc_index('4843265')).to be < 1
  #   # expect(resp.has_document?('4843265') ).to eq true
  #   # expect(rank(resp, 4843265)).to be <= 1
  #   # the old bib id was dropped, no one answered when I asked
  #   # the new bib id, I'm going to guess it's now 14867155
  #   expect(rank(resp, 14867155)).to be <= 1
  # end

  it 'Gut' do
    resp = solr_resp_ids_from_query('Gut')
    # puts resp.inspect # debug
    expect(rank(resp, 'ebs31871e')).to be <= 3

    resp = solr_resp_ids_from_journal_title_query('Gut')
    puts resp.inspect # debug
    expect(rank(resp, 'ebs31871e')).to be <= 2

    resp = solr_resp_ejournal_ids_only('q' => 'Gut')
    expect(rank(resp, 'ebs31871e')).to be <= 1
  end

  it 'Nature' do
    resp = solr_resp_ids_from_query('Nature')
    expect(rank(resp, 'ebs50974e')).to be <= 1

    resp = solr_resp_ids_from_journal_title_query('Nature')
    expect(rank(resp, 'ebs50974e')).to be <= 2

    resp = solr_resp_ejournal_ids_only('q' => 'Nature')
    expect(rank(resp, 'ebs50974e')).to be <= 1
  end

  it 'Heart' do
    resp = solr_resp_ids_from_query('Heart')
    expect(rank(resp, 'ebs32534e')).to be <= 10

    resp = solr_resp_ids_from_journal_title_query('Heart')
    expect(rank(resp, 'ebs32534e')).to be <= 2

    resp = solr_resp_ejournal_ids_only('q' => 'Heart')
    expect(rank(resp, 'ebs32534e')).to be <= 1
  end

  it 'Science' do
    resp = solr_resp_ids_from_query('Science')
    expect(rank(resp, 'ebs62477e')).to be <= 1

    resp = solr_resp_ids_from_journal_title_query('Science')
    expect(rank(resp, 'ebs62477e')).to be <= 5

    resp = solr_resp_ejournal_ids_only('q' => 'Science')
    expect(rank(resp, 'ebs62477e')).to be <= 1
  end

  it 'Neurology' do
    resp = solr_resp_ids_from_query('Neurology')
    expect(rank(resp, 'ebs51426e')).to be <= 5

    resp = solr_resp_ids_from_journal_title_query('Neurology')
    expect(rank(resp, 'ebs51426e')).to be <= 3

    resp = solr_resp_ejournal_ids_only('q' => 'Neurology')
    expect(rank(resp, 'ebs51426e')).to be <= 3
  end

  it 'Circulation' do
    resp = solr_resp_ids_from_query('Circulation')
    expect(rank(resp, 'ebs183081e')).to be <= 5

    resp = solr_resp_ids_from_journal_title_query('Circulation')
    expect(rank(resp, 'ebs183081e')).to be <= 3

    resp = solr_resp_ejournal_ids_only('q' => 'Circulation')
    expect(rank(resp, 'ebs183081e')).to be <= 3
  end

  it 'JAMA' do
    resp = solr_resp_ids_from_query('JAMA')
    expect(rank(resp, 'ebs38171e')).to be <= 10

    resp = solr_resp_ids_from_journal_title_query('JAMA')
    expect(rank(resp, 'ebs38171e')).to be <= 1

    resp = solr_resp_ejournal_ids_only('q' => 'JAMA')
    expect(rank(resp, 'ebs38171e')).to be <= 1
  end

  it 'Brain' do
    resp = solr_resp_ids_from_query('Brain')
    expect(rank(resp, 'ebs11782e')).to be <= 5

    resp = solr_resp_ids_from_journal_title_query('Brain')
    expect(rank(resp, 'ebs11782e')).to be <= 2

    resp = solr_resp_ejournal_ids_only('q' => 'Brain')
    expect(rank(resp, 'ebs11782e')).to be <= 2
  end

  it 'Lancet' do
    resp = solr_resp_ids_from_query('Lancet')
    expect(rank(resp, 'ebs45083e')).to be <= 5

    resp = solr_resp_ids_from_journal_title_query('Lancet')
    expect(rank(resp, 'ebs45083e')).to be <= 3

    resp = solr_resp_ejournal_ids_only('q' => 'Lancet')
    expect(rank(resp, 'ebs45083e')).to be <= 2
  end


  it 'Nation' do
    resp = solr_resp_ids_from_query('Nation')
    expect(rank(resp, 'ebs50607e')).to be <= 7

    resp = solr_resp_ids_from_journal_title_query('Nation')
    expect(rank(resp, 'ebs50607e')).to be <= 6

    resp = solr_resp_ejournal_ids_only('q' => 'Nation')
    expect(rank(resp, 'ebs50607e')).to be <= 6
  end
end

describe 'Searching for other one-word titles: ', :skip_travis do
  it 'JSTOR' do
    resp = solr_resp_ids_from_query('JSTOR')
    expect(rank(resp, 1959655)).to be <= 1
  end

  # NEXT-767 - Relevance ranking issue for MEDLINE
  it 'Medline' do
    resp = solr_resp_ids_from_query('medline')
    expect(rank(resp, 4066287)).to be <= 1
    expect(rank(resp, 8088762)).to be <= 3
  end
end
