# encoding: utf-8
require 'spec_helper'

describe 'Spectrum::SearchEngines::GoogleAppliance' do

  describe 'Libraries Website search for "books"' do
    before(:all) do
      @search_engine = Spectrum::SearchEngines::GoogleAppliance.new('q' => 'books')
    end

    it 'should get many items, successfully' do
      @search_engine.total_items.should be > 500
      @search_engine.successful?.should be true
    end

    it 'should have "next" but no "prev"' do
      @search_engine.previous_page?.should be false
      @search_engine.next_page?.should be true
    end


  end

  describe 'Libraries Website error handling' do

    it 'should raise an error if not query specified' do
      expect {
        Spectrum::SearchEngines::GoogleAppliance.new()
      }.to raise_error(RuntimeError)
    end

  end


end


