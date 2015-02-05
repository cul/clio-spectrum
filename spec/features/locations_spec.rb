require 'spec_helper'

describe 'Locations' do

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
    save_and_open_page
    save_and_open_screenshot
    page.should have_text("Call (646) 774 - 8613 between 9-5pm")

    # Test substring matching...
    visit location_display_path('NYS+Psychiatric+Institute')
    page.should have_text("Call (646) 774 - 8613 between 9-5pm")
  end

end
