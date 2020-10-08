require 'spec_helper'

require 'rake'

describe 'Locations' do
  context "\nYou may need to run 'rake hours:update_all RAILS_ENV=test' and 'rake locations:load RAILS_ENV=test'.  See README.\n" do
    before(:all) do
      # DatabaseCleaner.clean
      # Clio::Application.load_tasks
      # Rake::Task['locations:load'].invoke
      # Test suite doesn't rely on up-to-date hours content
      # Rake::Task['hours:update_all'].invoke
    end

    # NEXT-1118 - Avery link to "Make an Appointment"
    it 'should show backend-supplied location_notes in holdings box', js: true, focus: false do
      # Search for "By Appointment" items
      visit catalog_index_path(q: 'Avery Classics By appt', search_field: 'location')
      # Go to the item-detail page of the first item found
      within all('.result.document').first do
        all('a').first.click
      end

      expect(page).to have_css('.holdings')
      expect(page).to have_css('.location_notes')

      within('.location_notes') do
        expect(find('.location_note')).to have_text('By appointment only')
      end
    end

    # # NEXT-1129 - Request to change text of NYSPI
    # it 'should show correct phone for NYS Psychiatric Inst' do
    #
    #   # The full complete URL
    #   visit location_display_path('NYS+Psychiatric+Institute+Library+%28Circulation+Restricted%29')
    #   expect(page).to have_text("Call (646) 774 - 8613 between 9-5pm")
    #
    #   # Test substring matching...
    #   visit location_display_path('NYS+Psychiatric+Institute')
    #   expect(page).to have_text("Call (646) 774 - 8613 between 9-5pm")
    # end

    it 'should have a map of Butler if Location is Milstein', :skip_travis do
      visit location_display_path('Milstein+%5BButler%5D')
      expect(page).to have_css('.gmap_container')
      expect(page).to have_css('.well h1', text: 'Milstein')
    end

    it 'should have a map of Barnard if location is Barnard Archives', :skip_travis do
      visit location_display_path('Barnard+Archives+%28Non-Circulating%29')
      expect(page).to have_css('.gmap_container')
      expect(page).to have_css('.well h1', text: 'Barnard')
    end

    it 'should have a google map for a location with a map', :skip_travis do
      visit location_display_path('Butler+Stacks+%28Enter+at+the+Butler+Circulation+Desk%29')
      expect(page).to have_css('.gmap_container')
    end

    it 'should have a google map for a location with a slash' do
      visit location_display_path('Ancient%2FMedieval+Reading+Rm%2C+603+Butler+%28Non-Circulating%29')
      expect(page).to have_css('.gmap_container')
    end

    it 'should have a google map for the Comp Lit Reading Room' do
      visit location_display_path('Comp+Lit+%26+Society+Reading+Room%2C+615+Butler+%28Non-Circ%29')
      expect(page).to have_css('.gmap_container')
    end

    it 'should have a google map for the Edward Said Reading Room' do
      visit location_display_path('Edward+Said+Reading+Rm%2C+616+Butler+%28Non-Circulating%29')
      expect(page).to have_css('.gmap_container')
    end

    # it 'should not show the map for Lehman Suites' do
    #   visit location_display_path("Lehman+Suite%2C+406+SIA+%28Non-Circulating%29")
    #   expect(page).not_to have_css('.gmap_container')
    # end

    # it 'should show the map for Orthopaedic Surgery' do
    #   visit location_display_path("Orthopaedic+Surgery+%28Non-Circulating%29")
    #   expect(page).to have_css('.gmap_container')
    # end

    # it 'should show the map for NYS Psychiatric Institute' do
    #   visit location_display_path("NYS+Psychiatric+Institute+Library+%28Circulation+Restricted%29")
    #   expect(page).to have_css('.gmap_container')
    # end

    it 'should show the map for Barnard Center for Research on Women' do
      visit location_display_path('Barnard+Center+For+Research+On+Women%29')
      expect(page).to have_css('.gmap_container')
    end

    it 'shows the heading from the clio location data', :skip_travis do
      visit location_display_path('Butler+Stacks+%28Enter+at+the+Butler+Circulation+Desk%29')
      expect(page).to have_css('.well h1', text: 'Butler Stacks')
    end

    it 'has mouseover text on pins' do
      visit location_display_path('Butler+Stacks+%28Enter+at+the+Butler+Circulation+Desk%29')
      title = find('.gmap_container')['data-markers'].split('},{').select { |elt| elt.match(/\"location_code\":\"avery\"/) }[0]
      expect(title).to match(/\"marker_title\":\"Avery Library\"/)
    end

    it 'should have markers for all locations on the map' do
      visit location_display_path('Butler+Stacks+%28Enter+at+the+Butler+Circulation+Desk%29')
      # Why so precise?  What's special about this number?
      # expect(find('.gmap_container')['data-markers'].split('},{').count).to eq(28)
      # Let's switch to a reasonable range
      marker_count = find('.gmap_container')['data-markers'].split('},{').count
      expect(marker_count).to be > 20
      expect(marker_count).to be < 40
    end

    context 'infowindow', :selenium do
      it 'uses selenium driver' do
        expect(Capybara.current_driver).to be(:selenium)
      end

      it 'should display the infowindow for the current marker' do
        visit location_display_path('Avery+%28Non-Circulating%29')
        expect(page).to have_css('.infowindow.avery')
        expect(find('.infowindow').text).to match('Avery')
      end

      it 'opens the Butler infowindow for Milstein' do
        visit location_display_path('Milstein+%5BButler%5D')
        expect(page).to have_css('.infowindow.butler')
      end

      it 'opens the Barnard infowindow for Barnard Archives' do
        visit location_display_path('Barnard+Archives+%28Non-Circulating%29')
        expect(page).to have_css('.infowindow.barnard')
      end
    end
  end
end
