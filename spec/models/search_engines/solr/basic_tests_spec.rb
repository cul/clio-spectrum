# encoding: utf-8
require 'spec_helper'

describe 'Spectrum::SearchEngines::Solr', :vcr do
  solr_url = nil
  solr_url = SOLR_CONFIG['test']['url']
  # solr_url = SOLR_CONFIG['spectrum_subset']['url']

  # INTERFACE TESTING

  describe 'Setting the result-count parameter' do
    before(:each) do
      @result_count = 42
    end

    it 'should return that number of results' do
      eng = Spectrum::SearchEngines::Solr.new('source' => 'catalog', :q => 'Smith', :search_field => 'all_fields', :rows => @result_count, 'solr_url' => solr_url)
      expect(eng.results).to_not be_empty
      expect(eng.results.size).to equal(@result_count)
    end
  end

  # QUERY TESTING

  describe 'for searches with diacritics' do
    it 'should find an author with diacritics' do
      eng = Spectrum::SearchEngines::Solr.new(:source => 'catalog', :q => 'turk edebiyatinda', :search_field => 'author', 'solr_url' => solr_url)
      expect(eng.results).to_not be_empty
      expect(eng.results.first.fetch('author_display').first).to match /Edebiyat\u0131nda/
    end
  end

  # NEXT-178 - child does not stem to children
  # 10/2013 - with Stemming now being disabled, turn this into a validation test of
  # correct wildcard (child* ==> children)
  describe 'searches for "child* autobiography..." in Catalog' do
    it 'should find "autobiographies of children" ' do
      eng = Spectrum::SearchEngines::Solr.new(:source => 'catalog', :q => 'child* autobiography asian north american honolulu', :search_field => 'all_fields', 'solr_url' => solr_url)
      expect(eng.results).to_not be_empty
      expect(eng.results.first.fetch('title_display').first).to match(/reading Asian North American autobiographies of childhood/)
    end
  end

  # NEXT-389 - "Debt: The first 5,000 years"
  describe 'search for "debt the first 5000 years" in Catalog' do
    it 'should find "Debt: The first 5,000 years" ' do
      eng = Spectrum::SearchEngines::Solr.new(:source => 'catalog', :q => 'debt the first 5000 years', :search_field => 'all_fields', 'solr_url' => solr_url)
      expect(eng.results).to_not be_empty
      expect(eng.results.first.fetch('title_display').first).to match(/Debt/)
      expect(eng.results.first.fetch('title_display').first).to match(/the first 5,000 years/)
    end
  end

  # NEXT-404 - "Wildcarding MARC fields (960) does not appear to work"
  # RECONS185 - 6K records
  # RECONS186 - 3K records
  # RECONS18* - 15K records
  describe 'search for "RECONS18*" in Catalog' do
    it 'should find more than RECONS185 or RECONS186 alone' do
      r185 = Spectrum::SearchEngines::Solr.new(:source => 'catalog', :q => 'RECONS185', :search_field => 'all_fields', 'solr_url' => solr_url)
      r186 = Spectrum::SearchEngines::Solr.new(:source => 'catalog', :q => 'RECONS186', :search_field => 'all_fields', 'solr_url' => solr_url)
      r_wildcard = Spectrum::SearchEngines::Solr.new(:source => 'catalog', :q => 'RECONS18*', :search_field => 'all_fields', 'solr_url' => solr_url)
      expect(r_wildcard.total_items).to be > r185.total_items
      expect(r_wildcard.total_items).to be > r186.total_items
    end
  end

  # NEXT-415
  describe 'searches for "New Yorker" in Journals' do
    it 'should find "The New Yorker" as the first result' do
      eng = Spectrum::SearchEngines::Solr.new(:source => 'journals', :q => 'New Yorker', :search_field => 'all_fields', 'solr_url' => solr_url)
      expect(eng.results).to_not be_empty
      expect(eng.results.first.fetch('title_display').first).to match(/The.New.Yorker/)
    end
  end

  # NEXT-429
  describe 'catalog all-field searches with embedded space-colon-space' do
    it 'should return search results' do
      eng = Spectrum::SearchEngines::Solr.new(:source => 'catalog', :q => 'Clemens Krauss : Denk Display', :search_field => 'all_fields', 'solr_url' => solr_url)
      expect(eng.results).to_not be_empty
      expect(eng.results.first.fetch('title_display').first).to match /Clemens Krauss/
      expect(eng.results.first.fetch('title_display').first).to match /Denk Display/
    end
  end

  # NEXT-452
  describe 'catalog all-field searches for Judith Butler' do
    before(:each) do
    end

    it 'should return full-phrase title/author matches before split-field matches' do
      eng = Spectrum::SearchEngines::Solr.new(:source => 'catalog', :q => 'Judith Butler', :search_field => 'all_fields', :rows => @result_count, 'solr_url' => solr_url)
      expect(eng.results).not_to be_empty
      eng.results.each do |result|
        expect(result).to contain_in_fields(['Butler, Judith', 'Judith Butler'], 'title_display', 'subtitle_display', 'author_display')
      end
    end
  end

  # NEXT-478
  describe 'search for "Nature"' do
    it 'should return matches on "Nature" before "Naturalization"' do
      eng = Spectrum::SearchEngines::Solr.new(:source => 'catalog', :q => 'nature', :search_field => 'all_fields', 'solr_url' => solr_url)

      found_naturA = false
      eng.results.each do |result|
        if result.fetch('title_display').first && result.fetch('title_display').first.match(/naturALIZ/i)
          found_naturA = true
        end

        # after finding our first "natura*", there should be no more "nature" matches
        if found_naturA
          expect(result.fetch('title_display').first).to_not match(/naturE/i)
        end
      end
    end
  end
end
