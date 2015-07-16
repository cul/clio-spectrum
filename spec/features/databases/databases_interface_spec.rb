# encoding: utf-8

require 'spec_helper'

describe 'Databases', focus: false do

  # NEXT-843 - Database Alpha jump-list should respect non-filing indicator
  it "First-Letter facet should ignore leading 'The'", js: true do
    visit databases_index_path
    within 'div.a_to_z' do
      click_link('T')
    end

    # Our "T" results page should show many titles,
    # but only a few should include "The"
    expect(page).to have_css('.result.document .title', minimum: 20)
    expect(page).to have_css('.result.document .title', text: 'The T', maximum: 5)

    visit databases_index_path
    within 'div.a_to_z' do
      click_link('A')
    end

    # Our "A" results page should show many titles,
    # including at least one "The" and one "L'"
    expect(page).to have_css('.result.document .title', minimum: 20)
    expect(page).to have_css('.result.document .title', text: 'The A', minimum: 1)
    expect(page).to have_css('.result.document .title', text: "L'A", minimum: 1)

    within '#documents' do
      click_link('Academic Commons')
    end

    expect(find('#search_info')).to have_text 'Back to Results'
    expect(find('#search_info')).to have_text 'Previous'
    expect(find('#search_info')).to have_text 'Next'
    find('.start_over', text: 'Start Over')

    expect(page).to have_text 'Previous title: DigitalCommons'
    # NEXT-983 - Improvements to database discovery interface (styles, language)
    # Databases have custom label, "Search Database", instead of just "Online"
    expect(page).to have_text 'Search Database: http://www.columbia.edu/cgi-bin/cul/resolve?clio6662174'

    within '#search_info' do
      click_link 'Previous'
    end

    within '#search_info' do
      click_link 'Back to Results'
    end

    expect(find('.constraints-container')).to have_text 'You searched for: Starts With: Is A'
  end

  it 'should search by pairs of Discipline/Resource-Type filters correctly' do
   visit root_path
    # We should now be on QUICKSEARCH page
   expect(find('.landing_main .title')).to have_text('Quicksearch')
    # page.save_and_open_page # debug

   within('li.datasource_link[source="databases"]') do
     click_link('Databases')
   end
    # We should now be on DATABASES page
   expect(find('.landing_main .title')).to have_text('Databases')

    # Databases landing page...
   within 'div.databases_browse_by' do
     expect(page).to have_text('Browse by discipline')
     expect(page).to have_text('Browse by resource type')

     find('select#f_database_discipline_facet_', text: 'All Disciplines').click
     select('Social Sciences', from: 'f_database_discipline_facet_')

     find('select#f_database_resource_type_facet_', text: 'All Resource Types').click
     select('Text Collections', from: 'f_database_resource_type_facet_')

     find('button', text: 'Browse').click
   end

   within 'div.constraints-container' do
     # Unfortunately, the drop-down "Is"/"Is Not" menu is not really hidden to rspec...
     find('.constraint-box', text: %r{Discipline: Is .* Social Sciences})
     find('.constraint-box', text: %r{Resource Type: Is .* Text Collections})
   end

   expect(page).to have_css('.result.document', minimum: 10)

   # click_link('Start Over')
   first(:link, 'Start Over').click

    # Use the

   within 'div.databases_browse_by' do
     expect(page).to have_text('Browse by discipline')
     expect(page).to have_text('Browse by resource type')

     find('select#f_database_discipline_facet_', text: 'All Disciplines').click
     select('Sciences', from: 'f_database_discipline_facet_')

     find('select#f_database_resource_type_facet_', text: 'All Resource Types').click
     select('Music Scores', from: 'f_database_resource_type_facet_')

     find('button', text: 'Browse').click
   end

   within 'div.constraints-container' do
     # Unfortunately, the drop-down "Is"/"Is Not" menu is not really hidden to rspec...
     find('.constraint-box', text: %r{Discipline: Is .* Sciences})
     find('.constraint-box', text: %r{Resource Type: Is .* Music Scores})
   end
   expect(page).to have_text('No results found for your search')
 end

 # NEXT-1211 - When I do a blank ejournals search, view a title, and view the MARC record, my results revert back to the full catalog results
 it 'should preserve active_source through MARC view', js: true do
   firstTitle = '60 minutes'
   visit databases_index_path( q: '')
   expect(page).to have_text firstTitle


   click_link(firstTitle)
   expect(page).to have_text 'Back to Results | 1 of '
   expect(page).to have_text "Title " + firstTitle

   click_link('Display In')
   click_link('MARC View')
   page.should have_text 'Back to Results | 1 of '
   page.should have_text '245 0 0 |a ' + firstTitle

   # Nav links should preserve active datasource
   href = find_link('Back to Results')[:href]
   expect(href).to match( /\/databases\?/)
   href = find_link('Next')[:href]
   expect(href).to match( /\/databases\//)
   href = find_link('Return to Patron View')[:href]
   expect(href).to match( /\/databases\//)

   within '#show_toolbar' do
     click_link('Next')
   end
   page.should have_text 'Back to Results | « Previous | 2 of '

   # Nav links should preserve active datasource
   href = find_link('Back to Results')[:href]
   expect(href).to match( /\/databases\?/)
   href = find_link('Previous')[:href]
   expect(href).to match( /\/databases\//)
   href = find_link('Next')[:href]
   expect(href).to match( /\/databases\//)
   href = find_link('Return to Patron View')[:href]
   expect(href).to match( /\/databases\//)
 end


end
