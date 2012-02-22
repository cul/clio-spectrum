require "spec_helper"

describe "The catalog controller" do
  it "should let the user set the number of records" do
    visit catalog_index_path(:q => "test")
    page.should have_css('.result', :count => 15)
    within("#sortAndPerPage") do
      select('30', :name => 'per_page')
      click_button('update')
    end

    page.should have_css('.result', :count => 30)
  end
end
