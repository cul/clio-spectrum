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

  it "should search by pairs of Discipline/Resource-Type filters correctly" do
    visit root_path
    # find('li.datasource_link[source=database]').click
    find('li.datasource_link[source=databases]', :text => 'Databases').click

    # Databases landing page...
    within 'div.databases_browse_by' do
      page.should have_text('Browse by discipline')
      page.should have_text('Browse by resource type')

      find('select#f_database_hilcc_facet_', :text => "All Disciplines").click
      select('Social Sciences', :from => 'f_database_hilcc_facet_')

      find('select#f_database_resource_type_facet_', :text => "All Resource Types").click
      select('Text Collections', :from => 'f_database_resource_type_facet_')

      find('button', :text => 'Browse').click
    end

    within 'div.constraints-container' do
      # Unfortunately, the drop-down "Is"/"Is Not" menu is not really hidden to rspec...
      find('.constraint-box', text: %r{Discipline: Is .* Social Sciences} )
      find('.constraint-box', text: %r{Resource Type: Is .* Text Collections} )
    end

    page.should have_css('.result.document', :minimum => 10)

    click_link('Start Over')

    # Use the 

    within 'div.databases_browse_by' do
      page.should have_text('Browse by discipline')
      page.should have_text('Browse by resource type')

      find('select#f_database_hilcc_facet_', :text => "All Disciplines").click
      select('Sciences', :from => 'f_database_hilcc_facet_')

      find('select#f_database_resource_type_facet_', :text => "All Resource Types").click
      select('Music Scores', :from => 'f_database_resource_type_facet_')

      find('button', :text => 'Browse').click
    end


    within 'div.constraints-container' do
      # Unfortunately, the drop-down "Is"/"Is Not" menu is not really hidden to rspec...
      find('.constraint-box', text: %r{Discipline: Is .* Sciences} )
      find('.constraint-box', text: %r{Resource Type: Is .* Music Scores} )
    end
    page.should have_text('No results found for your search')
 end

end

