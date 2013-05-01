require 'spec_helper'

describe "Item Locations should show correct library hours" do
  
  it "for Avery Drawings & Archives", :js => true do
    visit catalog_path('8277276')
    page.should have_text('Avery Drawings & Archives')
    # page.save_and_open_page # debug
    click_link('Avery Drawings & Archives')
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

end

