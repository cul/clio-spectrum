# encoding: utf-8
require 'spec_helper'

describe 'Spectrum::Engines::Solr' do

  solr_url = nil
  # solr_url = SOLR_CONFIG['test']
  # solr_url = SOLR_CONFIG['spectrum_subset']['url']

  
  # INTERFACE TESTING

  describe 'Setting the result-count parameter' do
    before(:each) do
      @result_count = 42
    end

    it 'should return that number of results' do
      pending('until rows param works again')
      eng = Spectrum::Engines::Solr.new('source' => 'catalog', :q => 'Smith', :search_field => 'all_fields', :rows => @result_count, :solr_url => solr_url)
      eng.results.should_not be_empty
      eng.results.size.should equal(@result_count)
    end
  end


  # QUERY TESTING
  
  describe 'for searches with diacritics' do
    it 'should find an author with diacritics' do
      # eng = Spectrum::Engines::Solr.new(:source => 'catalog', :q => 'turk edebiyatinda', :search_field => 'author', :solr_url => solr_url)
      eng = Spectrum::Engines::Solr.new(:source => 'catalog', :q => 'turk edebiyatinda', :search_field => 'author', :solr_url => solr_url)
      eng.results.should_not be_empty
      # puts eng.solr_search_params
      eng.results.first.get('author_display').should include("Edebiyat\u0131nda")
    end
  end
  
  
  # NEXT-178 - child does not stem to children
  describe 'searches for "child autobiography..." in Catalog' do
    it 'should find "autobiographies of children" ' do
      # pending('revamp to how stopwords and/or phrases are handled')
      eng = Spectrum::Engines::Solr.new(:source => 'catalog', :q => 'child autobiography asian north american', :search_field => 'all_fields', :solr_url => solr_url)
      eng.results.should_not be_empty
      # puts eng.solr_search_params\
      # puts eng.results.first.get('title_display')
      eng.results.first.get('subtitle_display').should match(/reading Asian North American autobiographies of childhood/)
    end
  end

  
  # NEXT-415
  describe 'searches for "New Yorker" in Journals' do
    it 'should find "The New Yorker" as the first result' do
      # pending('revamp to how stopwords and/or phrases are handled')
      eng = Spectrum::Engines::Solr.new(:source => 'journals', :q => 'New Yorker', :search_field => 'all_fields', :solr_url => solr_url)
      eng.results.should_not be_empty
      # puts eng.solr_search_params\
      # puts eng.results.first.get('title_display')
      eng.results.first.get('title_display').should match(/The.New.Yorker/)
    end
  end
  
  
  # NEXT-429
  describe 'catalog all-field searches with embedded space-colon-space' do
    it 'should return search results' do
      # pending('revamp to how colon searches are handled')
      # pending('until gary reruns subset extract')
      eng = Spectrum::Engines::Solr.new(:source => 'catalog', :q => 'Clemens Krauss : Denk Display', :search_field => 'all_fields', :solr_url => solr_url)
      eng.results.should_not be_empty
      eng.results.first.get('title_display').should include('Clemens Krauss')
      eng.results.first.get('subtitle_display').should include('Denk Display')
    end
  end
  
  # NEXT-452
  describe 'catalog all-field searches for Judith Butler' do
    before(:each) do
      @result_count = 30
    end

    it 'should return full-phrase title/author matches before split-field matches' do
      pending('until rows param works again')
      eng = Spectrum::Engines::Solr.new(:source => 'catalog', :q => 'Judith Butler', :search_field => 'all_fields', :rows => @result_count, :solr_url => solr_url)
      eng.results.should_not be_empty
      # eng.results.size.should equal(@result_count)
      eng.results.each do |result|
        result.should contain_in_fields("Judith Butler", 'title_display', 'subtitle_display', 'author_display')
      end
    end
  end
  
  
end
