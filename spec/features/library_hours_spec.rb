require 'spec_helper'

describe "Item Locations should show correct library hours" do
  
  pending "ASYNC CLIO HOLDINGS LOAD NOT WORKING WITH CAPYBARA ???"
  
  it "for Avery Drawings & Archives", :js => true do
    visit catalog_path('8277276')
    page.should have_text('Avery Drawings & Archives')
# page.save_and_open_page # debug
    click_link('Avery Drawings & Archives - By appt. (Non-Circulating)')
    # page.save_and_open_page # debug
    page.should have_text('Avery Drawings & Archives')
    page.should have_link("Full Hours Info", :href=>"http://www.columbia.edu/cu/lweb/services/hours/index.html?library=averydr")
  end

  it "for Avery Drawings & Archives", :js => true do
    visit catalog_path('565036')
    page.should have_text('Avery Classics')
    click_link('Avery Classics')
    page.should have_text('Avery Classics')
    page.should have_link("Full Hours Info", :href=>"http://www.columbia.edu/cu/lweb/services/hours/index.html?library=averycl")
  end


  it "for Oral History Research Office", :js => true do
    visit catalog_path('4075929')
    page.should have_text('Oral History, 801 Butler')
    click_link('Oral History, 801 Butler')
    page.should have_text('Oral History')
    page.should have_link("Home Page", :href=>"http://library.columbia.edu/indiv/ccoh.html")
    page.should have_link("Full Hours Info", :href=>"http://www.columbia.edu/cu/lweb/services/hours/index.html?library=ohro")
  end

end

