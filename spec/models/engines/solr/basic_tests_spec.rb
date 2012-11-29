# encoding: utf-8
require 'spec_helper'

describe 'Spectrum::Engines::Solr' do

  solr_url = nil
  # solr_url = SOLR_CONFIG['test']
  solr_url = SOLR_CONFIG['spectrum_subset']
  
  describe 'for searches with diacritics' do
    it 'should find an author with diacritics' do
      eng = Spectrum::Engines::Solr.new(:source => 'catalog', :q => 'turk edebiyatinda', :search_field => 'author', :solr_url => solr_url)
      eng.results.should_not be_empty
      # puts eng.solr_search_params
      eng.results.first.get('author_display').should include("Edebiyat\u0131nda")
    end
  end
  
  # NEXT-415
  describe 'searches for "New Yorker" in Journals' do
    it 'should find "The New Yorker" as the first result' do
      pending('revamp to how stopwords and/or phrases are handled')
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
<<<<<<< HEAD
      eng = Spectrum::Engines::Solr.new(:source => 'catalog', :q => 'Clemens Krauss : Denk Display', :search_field => 'all_fields', :solr_url => solr_url).search
=======
      pending('revamp to how colon searches are handled')
      eng = Spectrum::Engines::Solr.new(:source => 'catalog', :q => 'Clemens Krauss : Denk Display', :search_field => 'all_fields')
>>>>>>> b019750d3274b23112c560838905783c8b3222aa
      eng.results.should_not be_empty
      eng.results.first.get('title_display').should include('Clemens Krauss')
      eng.results.first.get('subtitle_display').should include('Denk Display')
    end
  end
  
  # NEXT-452
<<<<<<< HEAD
  RSpec::Matchers.define :contain_in_fields do |target, *field_list|
    match do |doc|
      field_list.reduce(false) do |determination, field_name|
        target_as_regexp = Regexp.new( target.gsub(/ +/, '.*') )
        determination = determination or target_as_regexp.match( doc.get(field_name) )
      end
    end
    
    failure_message_for_should do |doc|
      doc_data = field_list.map do |field_name|
        "#{field_name}=#{ doc.get(field_name) }"
      end.join(', ')
      "expected that #{target} would be contained in doc fields (#{doc_data})"
    end
    
  end
  
  result_count = 30
  
  describe 'catalog all-field searches for Judith Butler' do
    it 'should return full-phrase title/author matches before split-field matches' do
      eng = Spectrum::Engines::Solr.new(:source => 'catalog', :q => 'Judith Butler', :search_field => 'all_fields', :per_page => result_count, :solr_url => solr_url).search
      eng.results.should_not be_empty
      eng.results.size.should equal(result_count)
=======
  
  
  describe 'catalog all-field searches for Judith Butler' do
    before(:each) do
      @result_count = 30
    end

    it 'should return full-phrase title/author matches before split-field matches' do
      pending('until title/author phrase searching is better')
      eng = Spectrum::Engines::Solr.new(:source => 'catalog', :q => 'Judith Butler', :search_field => 'all_fields', :rows => @result_count)
      eng.results.should_not be_empty
      eng.results.size.should equal(@result_count)
>>>>>>> b019750d3274b23112c560838905783c8b3222aa
      eng.results.each do |result|
        result.should contain_in_fields("Judith Butler", 'title_display', 'subtitle_display', 'author_display')
      end
    end
  end
  
  
end
