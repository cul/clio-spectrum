require 'spec_helper'

describe "The home page" do
  it "should let you perform a catalog advanced search", :js => true do
    visit root_path
    find('li.datasource_link[source=catalog]').click
    find('#catalog_q').should be_visible
    find('.landing_page.catalog .advanced_search').should_not be_visible


    find('.search_box.catalog .advanced_search_toggle').click
    find('.landing_page.catalog .advanced_search').should be_visible
    within '.landing_page.catalog .advanced_search' do
      select('Journal Title', :from => 'adv_1_field')
      fill_in 'adv_1_value', :with => "test"

      find('button[type=submit]').click()

    end

    find(".constraint-box").should have_content('Journal Title')

  end
end

