require 'spec_helper'

describe 'Locations' do

  # NEXT-1118 - Avery link to "Make an Appointment"
  it 'should include Location Notes', js: true do

    # The full complete URL
    visit location_display_path('Avery+Classics+-+By+appt.+%28Non-Circulating%29')
    page.should have_text("Located at: Avery Architectural & Fine Arts Library")
    find('.location_notes').should have_text("By appointment only")

    # Test substring matching...
    visit location_display_path('Avery+Classics+-+By+appt')
    page.should have_text("Located at: Avery Architectural & Fine Arts Library")
    find('.location_notes').should have_text("By appointment only")

    # And a further substring that doesn't match our app_config.yml location note
    visit location_display_path('Avery+Classics')
    page.should have_text("Located at: Avery Architectural & Fine Arts Library")
    # find('.location_notes').should_not have_text("By appointment only")
    page.should_not have_css('.location_notes')

  end
end