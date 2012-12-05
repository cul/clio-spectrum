# encoding: utf-8
require 'spec_helper'

describe 'Spectrum::Engines::Summon' do
  describe 'with parameters' do
    it 'should default to a clean search' do

      sum = Spectrum::Engines::Summon.new()
      sum.source.should be_nil
      sum.params.should_not have_key('s.ff')

    end

    it 'should load in default options as necessary' do
      # should not load in options unless it's a new search
      sum = Spectrum::Engines::Summon.new('source' => 'articles')
      sum.source.should == 'articles'
      sum.params.should_not have_key('s.ff')

      # should load in options with a new search
      sum = Spectrum::Engines::Summon.new('source' => 'articles', 'new_search' => true)
      sum.source.should == 'articles'
      sum.params.should have_key('s.ff')
      
      
    end
  end

  describe 'basic articles search' do
    before(:all) do
      @sum = Spectrum::Engines::Summon.new('source' => 'articles', 's.q' => 'hardnose dictator', 'new_search' => true)


    end

    it 'should find results' do
      @sum.documents.should_not be_empty
    end

    it 'should find a matching title result' do
      @sum.documents.first.title.should include('Hardnose')
    end

    it 'should not include newspaper articles' do
      @sum.search.query.facet_value_filters.should be_any { |f| f.negated? && f.value == "Newspaper Article" }
      @sum.documents.each do |doc|
        doc.content_type.should_not == 'Newspaper Article'
      end 

    end
  end
end

