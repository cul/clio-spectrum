require 'spec_helper'

describe 'Testing Author Searching', :skip_travis do


  # 100 0  |a Charles |b II, |c King of England, |d 1630-1685.
  it 'subfield 100$b (numeration)' do
    author_q = author_search_args('charles ii king')
    pub_country_fq = { 'fq' => 'pub_country_facet:"Ireland"' }
    resp = solr_resp_doc_ids_only( author_q.merge(pub_country_fq) )
    expect(resp.size).to be <= 100
    expect(rank(resp, 4541675)).to be <= 100
  end

  # 100 1  |a Seuss, |c Dr.
  it 'subfield 100$c (titles and words associated with a name)' do
    resp = solr_resp_doc_ids_only( author_search_args('dr seuss') )
    expect(resp.size).to be <= 50
    expect(rank(resp, 3157951)).to be <= 50
  end

  # 100 1  |a Reich, Steve, |d 1936-
  # 100 1  |a Reich, Steve, |d 1936- |e composer.
  it 'subfield 100$d (dates associated with a name)' do
    resp = solr_resp_doc_ids_only( author_search_args('steve reich 1936') )
    expect(resp.size).to be <= 200
    expect(rank(resp, 195395)).to be <= 50
    expect(rank(resp, 12028590)).to be <= 20
  end
  
  # Portrait of a Man, Said to be Admiral Samuel Hood, Viscount Hood (1724-1816).
  # 100 1  |a Gainsborough, Thomas, |d 1727-1788, |e artist, |j Follower of |0 http://id.loc.gov/authorities/names/n79055449
  it 'subfield 100$j (attribution qualifier)' do
    resp = solr_resp_doc_ids_only( author_search_args('gainsborough follower') )
    expect(resp.size).to be <= 10
    expect(rank(resp, 12003759)).to be <= 10
  end

  # H.G. Wells in love : postscript to An experiment in autobiography
  # 100 1  |a Wells, H. G. |q (Herbert George), |d 1866-1946.
  it 'subfield 100$q (fuller form of name)' do
    author_q = author_search_args('herbert george wells')
    subject_fq = { 'fq' => 'subject_topic_facet:"Relations with women"' }
    resp = solr_resp_doc_ids_only( author_q.merge(subject_fq) )
    expect(resp.size).to be <= 10
    expect(rank(resp, 276585)).to be <= 10
  end
  
end

