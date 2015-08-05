# encoding: utf-8
require 'spec_helper'

describe 'Spectrum::SearchEngines::GoogleAppliance' do

  describe 'Libraries Website search for "books"' do
    before(:all) do
      @search_engine = Spectrum::SearchEngines::GoogleAppliance.new('q' => 'books')
    end

    it 'should get many items, successfully' do
      expect(@search_engine.total_items).to be > 500
      expect(@search_engine.successful?).to be true
    end

    it 'should have "next" but no "prev"' do
      expect(@search_engine.previous_page?).to be false
      expect(@search_engine.next_page?).to be true
    end

  end

  describe 'Libraries Website error handling' do

    it 'should raise an error if not query specified' do
      expect do
        Spectrum::SearchEngines::GoogleAppliance.new
      end.to raise_error(RuntimeError)
    end

  end

end
