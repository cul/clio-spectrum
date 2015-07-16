require 'spec_helper'

describe 'Locations' do
  context "\nYou may need to run 'rake hours:sync RAILS_ENV=test' and 'rake locations:load RAILS_ENV=test'.  See README.\n" do

    # NEXT-1118 - Avery link to "Make an Appointment"
    # OLD WAY - FROM APP_CONFIG - SHOWED UP ON /LOCATIONS/ PAGE
    # it 'should include Location Notes', js: true do
    #   # The full complete URL
    #   visit location_display_path('Avery+Classics+-+By+appt.+%28Non-Circulating%29')
    #   expect(page).to have_text("Located at: Avery Architectural & Fine Arts Library")
    #   expect(find('.location_notes')).to have_text("By appointment only")
    # 
    #   # Test substring matching...
    #   visit location_display_path('Avery+Classics+-+By+appt')
    #   expect(page).to have_text("Located at: Avery Architectural & Fine Arts Library")
    #   expect(find('.location_notes')).to have_text("By appointment only")
    # 
    #   # And a further substring that doesn't match our app_config.yml location note
    #   visit location_display_path('Avery+Classics')
    #   expect(page).to have_text("Located at: Avery Architectural & Fine Arts Library")
    #   expect(page).to_not have_css('.location_notes')
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
        expect(find('.location_note')).to have_text("By appointment only")
      end
    end


    # NEXT-1129 - Request to change text of NYSPI
    it 'should show correct phone for NYS Psychiatric Inst', js: true do

    # The full complete URL
    visit location_display_path('NYS+Psychiatric+Institute+Library+%28Circulation+Restricted%29')
    expect(page).to have_text("Call (646) 774 - 8613 between 9-5pm")

    # Test substring matching...
    visit location_display_path('NYS+Psychiatric+Institute')
    expect(page).to have_text("Call (646) 774 - 8613 between 9-5pm")
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

    it 'should not show the map for Lehman Suites', js: true do
      visit location_display_path("Lehman+Suite%2C+406+SIA+%28Non-Circulating%29")
      expect(page).not_to have_css('.gmap_container')
    end

    it 'should show the map for Orthopaedic Surgery', js: true do
      visit location_display_path("Orthopaedic+Surgery+%28Non-Circulating%29")
      expect(page).to have_css('.gmap_container')
    end

    it 'should show the map for NYS Psychiatric Institute', js: true do
      visit location_display_path("NYS+Psychiatric+Institute+Library+%28Circulation+Restricted%29")
      expect(page).to have_css('.gmap_container')
    end

    it 'should show the map for Barnard Center for Research on Women', js: true do
      visit location_display_path("Barnard+Center+For+Research+On+Women%29")
      expect(page).to have_css('.gmap_container')
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
      expect(find('.gmap_container')['data-markers'].split('},{').count).to eq(28)
    end

    context 'infowindow', selenium: true  do

      it 'uses selenium driver' do
        expect(Capybara.current_driver).to be(:selenium)
      end

      it 'should display the infowindow for the current marker' do
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
end
