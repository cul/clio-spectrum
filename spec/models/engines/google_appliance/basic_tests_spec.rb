# encoding: utf-8
require 'spec_helper'

describe 'Spectrum::Engines::GoogleAppliance' do

  describe 'Libraries Website search for "books"' do
    before(:all) do
      @engine = Spectrum::Engines::GoogleAppliance.new('q' => 'books')
    end

    it 'should get many items, successfully' do
      @engine.total_items.should be > 500
      @engine.successful?.should be true
    end

    it 'should have "next" but no "prev"' do
      @engine.previous_page?.should be false
      @engine.next_page?.should be true
    end


  end

  describe 'Libraries Website error handling' do

    it 'should raise an error if not query specified' do
      expect {
        Spectrum::Engines::GoogleAppliance.new()
      }.to raise_error(RuntimeError)
    end

  end


end


