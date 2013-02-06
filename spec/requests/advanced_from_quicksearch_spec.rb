require 'spec_helper'

describe "The home page" do
  it "should let you perform a catalog advanced search", :js => true do 
    visit root_path
    find('li.datasource_link[source=catalog]').click
    find('#catalog_q').should be_visible
    find('.advanced_search_well').should_not be_visible


    find('.advanced_search_toggle').click
    find('.advanced_search_well').should be_visible
    within '.advanced_search_well' do
      fill_in 'journal_title', :with => "test"

      find('button[type=submit]').click()
      
    end

    find(".constraint-box").should have_content('Journal Title')

  end
end

