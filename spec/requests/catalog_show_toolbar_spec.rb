require "spec_helper"
describe "Catalog show page", :js => true do
  it "should show a next and previous link when clicked through a search" do
    visit catalog_index_path(:q => 'test')
    first('.result .title a').click
    page.should have_css('#navigation')
    page.should have_css('#search_info')

  end
end
