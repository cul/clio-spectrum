require 'spec_helper'

# NEXT-330 - Single word journal titles continue to be a problem
#   mentions "Brain, Science, Lancet"
# NEXT-745 - Relevancy ranking clarification
#   mentions Lancet ("The Lancet"), Nation ("The Nation")
# NEXT-867 - The journal reproduction is not retrieved when searching for reproduction
# and also:  Gut, Nature, Heart, Science, Neurology, Circulation
describe 'Searching for one-word titles: ', :skip_travis do
  it 'Reproduction' do
    resp = solr_resp_ids_from_query('Reproduction')
    # expect(resp.get_first_doc_index({"id" => "4843265"})).to be < 1
    # expect(resp.has_document?({"id" => "4843265"}) ).to eq true
    # puts "RANK:" + rank(resp, 48432659).to_s
    # expect(resp.get_first_doc_index('4843265')).to be < 1
    # expect(resp.has_document?('4843265') ).to eq true
    expect(rank(resp, 4843265)).to be <= 1
  end

  it 'Gut' do
    resp = solr_resp_ids_from_query('Gut')
    resp.inspect
    expect(rank(resp, 4842087)).to be <= 3
    expect(rank(resp, 3942290)).to be <= 3

    resp = solr_resp_ids_from_journal_title_query('Gut')
    expect(rank(resp, 4842087)).to be <= 2

    resp = solr_resp_ejournal_ids_only('q' => 'Gut')
    expect(rank(resp, 4842087)).to be <= 1
  end

  it 'Nature' do
    resp = solr_resp_ids_from_query('Nature')
    expect(rank(resp, 3385138)).to be <= 5

    resp = solr_resp_ids_from_journal_title_query('Nature')
    expect(rank(resp, 3385138)).to be <= 5

    resp = solr_resp_ejournal_ids_only('q' => 'Nature')
    expect(rank(resp, 3385138)).to be <= 5
  end

  it 'Heart' do
    resp = solr_resp_ids_from_query('Heart')
    expect(rank(resp, 4842107)).to be <= 10

    resp = solr_resp_ids_from_journal_title_query('Heart')
    expect(rank(resp, 4842107)).to be <= 2

    resp = solr_resp_ejournal_ids_only('q' => 'Heart')
    expect(rank(resp, 4842107)).to be <= 1
  end

  it 'Science' do
    resp = solr_resp_ids_from_query('Science')
    expect(rank(resp, 3328066)).to be <= 1

    resp = solr_resp_ids_from_journal_title_query('Science')
    expect(rank(resp, 3328066)).to be <= 5

    resp = solr_resp_ejournal_ids_only('q' => 'Science')
    expect(rank(resp, 3328066)).to be <= 1
  end

  it 'Neurology' do
    resp = solr_resp_ids_from_query('Neurology')
    expect(rank(resp, 3385162)).to be <= 5

    resp = solr_resp_ids_from_journal_title_query('Neurology')
    expect(rank(resp, 3385162)).to be <= 1

    resp = solr_resp_ejournal_ids_only('q' => 'Neurology')
    expect(rank(resp, 3385162)).to be <= 1
  end

  it 'Circulation' do
    resp = solr_resp_ids_from_query('Circulation')
    expect(rank(resp, 3384258)).to be <= 5

    resp = solr_resp_ids_from_journal_title_query('Circulation')
    expect(rank(resp, 3384258)).to be <= 1

    resp = solr_resp_ejournal_ids_only('q' => 'Circulation')
    expect(rank(resp, 3384258)).to be <= 1
  end

  it 'JAMA' do
    resp = solr_resp_ids_from_query('JAMA')
    expect(rank(resp, 3429848)).to be <= 10

    resp = solr_resp_ids_from_journal_title_query('JAMA')
    expect(rank(resp, 3429848)).to be <= 2

    resp = solr_resp_ejournal_ids_only('q' => 'JAMA')
    expect(rank(resp, 3429848)).to be <= 2
  end

  it 'Brain' do
    resp = solr_resp_ids_from_query('Brain')
    expect(rank(resp, 3398529)).to be <= 5

    resp = solr_resp_ids_from_journal_title_query('Brain')
    expect(rank(resp, 3398529)).to be <= 1

    resp = solr_resp_ejournal_ids_only('q' => 'Brain')
    expect(rank(resp, 3398529)).to be <= 1
  end

  it 'Lancet' do
    resp = solr_resp_ids_from_query('Lancet')
    expect(rank(resp, 3429912)).to be <= 5

    resp = solr_resp_ids_from_journal_title_query('Lancet')
    expect(rank(resp, 3429912)).to be <= 5

    resp = solr_resp_ejournal_ids_only('q' => 'Lancet')
    expect(rank(resp, 3429912)).to be <= 5
  end

  it 'Nation' do
    resp = solr_resp_ids_from_query('Nation')
    expect(rank(resp, 3327456)).to be <= 20

    resp = solr_resp_ids_from_journal_title_query('Nation')
    expect(rank(resp, 3327456)).to be <= 20

    resp = solr_resp_ejournal_ids_only('q' => 'Nation')
    expect(rank(resp, 3327456)).to be <= 20
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
