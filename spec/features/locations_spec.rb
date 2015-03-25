require 'spec_helper'

describe 'Locations' do

  before :suite do
    Location.clear_and_load_fixtures!
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

    expect(page).to have_css('.holdings')

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

  it 'should have a map of Butler if Location is Milstein', js: true do
    visit location_display_path("Milstein+%5BButler%5D")
    expect(page).to have_css('.gmap_container')
    expect(page).to have_css('.well h1', text: "Butler Library")
  end

  it 'should have a map of Barnard if location is Barnard Archives', js: true do
    visit location_display_path("Barnard+Archives+%28Non-Circulating%29")
    expect(page).to have_css('.gmap_container')
    expect(page).to have_css('.well h1', text: "Barnard Archives and Special Collections")
  end

  it 'should have a google map for a location with a map', js: true do
    visit location_display_path("Butler+Stacks+%28Enter+at+the+Butler+Circulation+Desk%29")
    expect(page).to have_css('.gmap_container')
  end

  it 'should have a google map for a location with a slash', js: true do
    visit location_display_path("Ancient%2FMedieval+Reading+Rm%2C+603+Butler+%28Non-Circulating%29")
    expect(page).to have_css('.gmap_container')
  end

  it 'should have a google map for the Comp Lit Reading Room', js: true do
    visit location_display_path("Comp+Lit+%26+Society+Reading+Room%2C+615+Butler+%28Non-Circ%29")
    expect(page).to have_css('.gmap_container')
  end

  it 'should have a google map for the Edward Said Reading Room', js: true do
    visit location_display_path("Edward+Said+Reading+Rm%2C+616+Butler+%28Non-Circulating%29")
    expect(page).to have_css('.gmap_container')
  end

  it 'should not have a google map for a location without a map', js: true do
    visit location_display_path("Orthopaedic+Surgery+Oversize+%28Non-Circulating%29")
    expect(page).not_to have_css('.gmap_container')
  end

  it 'should not show the map for Lehman Suites', js: true do
    visit location_display_path("Lehman+Suite%2C+406+SIA+%28Non-Circulating%29")
    expect(page).not_to have_css('.gmap_container')
  end

  it 'shows the heading from the clio location data' do
    visit location_display_path("Butler+Stacks+%28Enter+at+the+Butler+Circulation+Desk%29")
    expect(page).to have_css('.well h1', text: "Butler Library")
  end

  it 'has mouseover text on pins' do
    visit location_display_path("Butler+Stacks+%28Enter+at+the+Butler+Circulation+Desk%29")
    title = find('.gmap_container')['data-markers'].split('},{').select{|elt| elt.match(/\"location_code\":\"avery\"/)}[0]
    expect(title).to match(/\"marker_title\":\"Avery Library\"/)
  end

  it 'should have markers for all locations on the map', js: true  do
    visit location_display_path("Butler+Stacks+%28Enter+at+the+Butler+Circulation+Desk%29")
    expect(find('.gmap_container')['data-markers'].split('},{').count).to eq(26)
  end

  context 'infowindow', type: :selenium  do
    before{Capybara.current_driver = :selenium}

    it 'should display the infowindow for the current marker', js: true do
      visit location_display_path("Avery+%28Non-Circulating%29")
      expect(page).to have_css('.infowindow.avery')
      expect(find('.infowindow').text).to match('Avery')
    end

    it "opens the Butler infowindow for Milstein" do
      visit location_display_path("Milstein+%5BButler%5D")
      expect(page).to have_css('.infowindow.butler')
    end

    it "opens the Barnard infowindow for Barnard Archives" do
      visit location_display_path("Barnard+Archives+%28Non-Circulating%29")
      expect(page).to have_css('.infowindow.barnard')
    end
  end

end
