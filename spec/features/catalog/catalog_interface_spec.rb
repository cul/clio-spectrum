require 'spec_helper'

# NEXT-705 - "All Fields" should be default, and should be first option
describe "Catalog Advanced Search" do
  it "should default to 'All Fields'", :js => true do
    visit root_path
    find('li.datasource_link[source=catalog]').click

    find('.search_box.catalog .advanced_search_toggle').click

    find('.landing_page.catalog .advanced_search').should be_visible

    within '.landing_page.catalog .advanced_search' do

      # For each of our five advanced-search fields...
      (1..5).each do |i|
        select_id = "adv_#{i}_field"

        # The select should exist, and "All Fields" should be selected
        has_select?(select_id, :selected => 'All Fields').should == true

        # "All Fields" should be the first option in the drop-down select menu
        within("select#adv_1_field") do
          first('option').text.should == "All Fields"
        end

      end

    end

  end
end

