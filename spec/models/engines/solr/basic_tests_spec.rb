# encoding: utf-8
require 'spec_helper'

describe 'Spectrum::Engines::Solr' do

  solr_url = nil
  solr_url = SOLR_CONFIG['test']['url']
  # solr_url = SOLR_CONFIG['spectrum_subset']['url']

  
  # INTERFACE TESTING

  describe 'Setting the result-count parameter' do
    before(:each) do
      @result_count = 42
    end

    it 'should return that number of results' do
      eng = Spectrum::Engines::Solr.new('source' => 'catalog', :q => 'Smith', :search_field => 'all_fields', :rows => @result_count, 'solr_url' => solr_url)
      
# puts eng
# puts eng.inspect
# puts eng.results      
      
      eng.results.should_not be_empty
      eng.results.size.should equal(@result_count)
    end
  end


  # QUERY TESTING
  
  describe 'for searches with diacritics' do
    it 'should find an author with diacritics' do
      # eng = Spectrum::Engines::Solr.new(:source => 'catalog', :q => 'turk edebiyatinda', :search_field => 'author', 'solr_url' => solr_url)
      eng = Spectrum::Engines::Solr.new(:source => 'catalog', :q => 'turk edebiyatinda', :search_field => 'author', 'solr_url' => solr_url)
      eng.results.should_not be_empty
      # puts eng.solr_search_params
      eng.results.first.get('author_display').should include("Edebiyat\u0131nda")
    end
  end
  
  
  # NEXT-178 - child does not stem to children
  describe 'searches for "child autobiography..." in Catalog' do
    it 'should find "autobiographies of children" ' do
      # pending('revamp to how stopwords and/or phrases are handled')
      eng = Spectrum::Engines::Solr.new(:source => 'catalog', :q => 'child autobiography asian north american', :search_field => 'all_fields', 'solr_url' => solr_url)
      # puts eng.solr_search_params
      eng.results.should_not be_empty
      # puts eng.results.first.get('title_display')
      eng.results.first.get('subtitle_display').should match(/reading Asian North American autobiographies of childhood/)
    end
  end

  # NEXT-389 - "Debt: The first 5,000 years"
  describe 'search for "debt the first 5000 years" in Catalog' do
    it 'should find "Debt: The first 5,000 years" ' do
      eng = Spectrum::Engines::Solr.new(:source => 'catalog', :q => 'debt the first 5000 years', :search_field => 'all_fields', 'solr_url' => solr_url)
      eng.results.should_not be_empty
      eng.results.first.get('title_display').should match(/Debt/)
      eng.results.first.get('subtitle_display').should match(/the first 5,000 years/)
    end
  end

  # NEXT-404 - "Wildcarding MARC fields (960) does not appear to work"
  # 2165B   - 1868 records ()
  # 2165BAP -  444 records
  # 2165B*  - 2125 records
  describe 'search for "2165B*" in Catalog' do
    it 'should find more than 2165B or 2165BAP alone' do
      eng_b = Spectrum::Engines::Solr.new(:source => 'catalog', :q => '2165B', :search_field => 'all_fields', 'solr_url' => solr_url)
      eng_bap = Spectrum::Engines::Solr.new(:source => 'catalog', :q => '2165BAP', :search_field => 'all_fields', 'solr_url' => solr_url)
      eng_wildcard = Spectrum::Engines::Solr.new(:source => 'catalog', :q => '2165B*', :search_field => 'all_fields', 'solr_url' => solr_url)
      eng_wildcard.total_items.should be > eng_b.total_items
      eng_wildcard.total_items.should be > eng_bap.total_items
    end
  end

  
  # NEXT-415
  describe 'searches for "New Yorker" in Journals' do
    it 'should find "The New Yorker" as the first result' do
       pending('revamp to how stopwords and/or phrases are handled')
      eng = Spectrum::Engines::Solr.new(:source => 'journals', :q => 'New Yorker', :search_field => 'all_fields', 'solr_url' => solr_url)
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
      eng = Spectrum::Engines::Solr.new(:source => 'catalog', :q => 'Clemens Krauss : Denk Display', :search_field => 'all_fields', 'solr_url' => solr_url)
      eng.results.should_not be_empty
      eng.results.first.get('title_display').should include('Clemens Krauss')
      eng.results.first.get('subtitle_display').should include('Denk Display')
    end
  end
  
  # NEXT-452
  describe 'catalog all-field searches for Judith Butler' do
    before(:each) do
       
    end

    it 'should return full-phrase title/author matches before split-field matches' do
      
      
      eng = Spectrum::Engines::Solr.new(:source => 'catalog', :q => 'Judith Butler', :search_field => 'all_fields', :rows => @result_count, 'solr_url' => solr_url)
      eng.results.should_not be_empty
      # eng.results.size.should equal(@result_count)
      eng.results.each do |result|
        result.should contain_in_fields(["Butler, Judith", "Judith Butler"], 'title_display', 'subtitle_display', 'author_display') 
      end
    end
  end
  
  # NEXT-478
  describe 'search for "Nature"' do
    it 'should return matches on "Nature" before "Naturalization"' do
      eng = Spectrum::Engines::Solr.new(:source => 'catalog', :q => 'nature', :search_field => 'all_fields', 'solr_url' => solr_url)
      
      # puts "XXXXXXXXXXXX   results.size: #{eng.results.size.to_s}"
      found_naturA = false
      eng.results.each do |result|
        # puts "--"
        # puts result.get('title_display') || 'emtpy-title'
        # puts result.get('subtitle_display') || 'emtpy-subtitle'
        if (result.get('title_display') && result.get('title_display').match(/naturA/i))
          found_naturA = true
        end

        # after finding our first "natura*", there should be no more "nature" matches
        if (found_naturA) 
          result.get('title_display').should_not match(/naturE/i)
        end
      end
    end
  end
  
  
  
  # NEXT-514
  describe 'search for "women physics" in catalog' do
    it 'should return exact matches before stemmed terms' do
      
      pending('clarity of desired behavior')
      
      eng = Spectrum::Engines::Solr.new(:source => 'catalog', :q => 'women physics', :search_field => 'all_fields', 'solr_url' => solr_url, :rows => 100)
      
      # puts "XXXXXXXXXXXX   results.size: #{eng.results.size.to_s}"
      
      found_unstemmed = false
      
      eng.results.each do |result|
        # puts "--"
        # puts result.get('title_display') || 'emtpy-title'
        # puts result.get('subtitle_display') || 'emtpy-subtitle'
        
        found_text = result.get('title_display').to_s + " " + result.get('subtitle_display').to_s
        puts found_text
        
        if (found_unstemmed == false \
            && ( ! found_text.match(/physics/i) || ! found_text.match(/women/i) )
            )
            puts "setting unstemmed to true for: " + found_text
            found_unstemmed = true
        end

        # If I've found any unstemmed, I should not then later see the terms verbatim
        if (found_unstemmed == true)
          result.get('title_display').to_s.should_not match(/women.*physics/i)
          result.get('title_display').to_s.should_not match(/physics.*women/i)
          result.get('subtitle_display').to_s.should_not match(/women.*physics/i)
          result.get('subtitle_display').to_s.should_not match(/physics.*women/i)
        end
        
            
      end
    end
  end
  
  
#   # NEXT-525
#    describe 'catalog search for "illustrations 2012" in butler stacks' do
#      it 'should not return duplicate results' do
#        eng = Spectrum::Engines::Solr.new(:source => 'catalog', :q => 'illustrations 2012', :search_field => 'all_fields', :fq => 'location_facet:Butler+Stacks' , 'solr_url' => solr_url)
#        
#        # 'f[location_facet][]' => 'Butler+Stacks'
# puts eng.solr_search_params
#       
#        foundBibList = Array.new
# puts "XXXXXXXXXXXX   results.size: #{eng.results.size.to_s}"
#        eng.results.each do |result|
#          bib = result.get('clio_id_display')
# puts "XXXXXXXXXXXX   bib: #{bib} title: #{result.get('title_display')}"
#          foundBibList.should_not include(bib)
#          foundBibList.push(bib)
#        end
#      end
#    end
   
  
end


