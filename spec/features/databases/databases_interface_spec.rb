# encoding: utf-8

require 'spec_helper'


describe "Databases", :focus => false do

  # NEXT-843 - Database Alpha jump-list should respect non-filing indicator
  it "First-Letter facet should ignore leading 'The'", :js => true do
    visit databases_index_path
    within 'div.a_to_z' do
      click_link('T')
    end

    # Our "T" results page should show many titles, 
    # but only a few should include "The"
    page.should have_css('.result.document .title', :minimum => 20)
    page.should have_css('.result.document .title', :text => "The T", :maximum => 5)

    visit databases_index_path
    within 'div.a_to_z' do
      click_link('A')
    end

    # Our "A" results page should show many titles, 
    # including at least one "The" and one "L'"
    page.should have_css('.result.document .title', :minimum => 20)
    page.should have_css('.result.document .title', :text => "The A", :minimum => 1)
    page.should have_css('.result.document .title', :text => "L'A", :minimum => 1)

  end

end

