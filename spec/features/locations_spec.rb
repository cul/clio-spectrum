require 'spec_helper'
require 'rake'

describe 'Locations' do

  before do
    Location.clear_and_load_fixtures!
    Rake.application.rake_require 'tasks/solr_ingest'
    Rake.application.rake_require 'tasks/sync_hours'
    Rake::Task.define_task(:environment)
    Rake.application.invoke_task 'hours:sync'
  end
  # NEXT-1118 - Avery link to "Make an Appointment"
  # OLD WAY - FROM APP_CONFIG - SHOWED UP ON /LOCATIONS/ PAGE
  # it 'should include Location Notes', js: true do
  #   # The full complete URL
  #   visit location_display_path('Avery+Classics+-+By+appt.+%28Non-Circulating%29')
  #   page.should have_text("Located at: Avery Architectural & Fine Arts Library")
  #   find('.location_notes').should have_text("By appointment only")
  # 
  #   # Test substring matching...
  #   visit location_display_path('Avery+Classics+-+By+appt')
  #   page.should have_text("Located at: Avery Architectural & Fine Arts Library")
  #   find('.location_notes').should have_text("By appointment only")
  # 
  #   # And a further substring that doesn't match our app_config.yml location note
  #   visit location_display_path('Avery+Classics')
  #   page.should have_text("Located at: Avery Architectural & Fine Arts Library")
  #   page.should_not have_css('.location_notes')
  # end
  # NEW WAY - SUPPLIED FROM BACKEND - SHOWS ONLY ON ITEM DETAIL PAGE
  it 'should show backend-supplied location_notes in holdings box', js: true do
    # Search for "By Appointment" items
    visit catalog_index_path( {q: 'Avery Classics By appt', search_field: 'location'} )
    # Go to the item-detail page of the first item found
    within all('.result.document').first do
      all('a').first.click
    end

    page.should have_css('.holdings')

    within('.location_notes') do
      find('.location_note').should have_text("By appointment only")
    end
  end


  # NEXT-1129 - Request to change text of NYSPI
  it 'should show correct phone for NYS Psychiatric Inst', js: true do

    # The full complete URL
    visit location_display_path('NYS+Psychiatric+Institute+Library+%28Circulation+Restricted%29')
    page.should have_text("Call (646) 774 - 8613 between 9-5pm")

    # Test substring matching...
    visit location_display_path('NYS+Psychiatric+Institute')
    page.should have_text("Call (646) 774 - 8613 between 9-5pm")
  end

  it 'should have a google map', js: true do
    visit location_display_path("Butler+Stacks+%28Enter+at+the+Butler+Circulation+Desk%29")
    expect(page).to have_css('.gmap_container')
    save_and_open_page
  end

  it 'shows the title from the clio location data' do
    pending
  end

  it 'has mouseover text on pins' do
    visit location_display_path("Butler+Stacks+%28Enter+at+the+Butler+Circulation+Desk%29")
    title = find('.gmap_container')['data-markers'].split('},{').select{|elt| elt.match(/\"library_code\":\"butler\"/)}[0]
    expect(title).to match(/\"marker_title\":\"Butler Library\"/)
  end

  it 'should have markers for all locations on the map', js: true  do
    visit location_display_path("Butler+Stacks+%28Enter+at+the+Butler+Circulation+Desk%29")
    expect(find('.gmap_container')['data-markers'].split('},{').count).to eq(27)
  end













  it 'should display the infowindow for the current marker', js: true do
    Capybara.current_driver = :poltergeist
    visit location_display_path("Avery+%28Non-Circulating%29")
    save_and_open_page
    expect(find('.gmap_container')['data-markers'].split('},{').count).to eq(27)
    expect(find('.infowindow').text).to match('Avery')
  end
end
