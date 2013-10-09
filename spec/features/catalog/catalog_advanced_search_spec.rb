require 'spec_helper'

describe "Catalog Advanced Search" do

  it "should be accessible from the home page", :js => true do
    # NEXT-713, NEXT-891 - A Journal Title search should find Newspapers

    # Use this string within the below test
    search_text = 'Japan Times & Mail'

    visit root_path
    find('li.datasource_link[source=catalog]').click
    find('#catalog_q').should be_visible
    page.should have_no_selector('.landing_page.catalog .advanced_search')

    find('.search_box.catalog .advanced_search_toggle').click
    find('.landing_page.catalog .advanced_search').should be_visible
    within '.landing_page.catalog .advanced_search' do
      select('Journal Title', :from => 'adv_1_field')
      fill_in 'adv_1_value', :with => search_text
      find('button[type=submit]').click()
    end

    find(".constraint-box").should have_content('Journal Title: ' + search_text)

    # And the search results too...
    # (struggling to make a regexp work, to do case-insensitive match...)
    # page.body.should match(%r{#{string}}i)
    # page.find 'li.line-item', text: %r{Awesome Line Item}i 
    # all('.result.document').first.should have_content(search_text)
    # all('.result.document').first.should match(%r{#{search_text}}i)
    all('.result.document').first.find 'a', text: %r{#{search_text}}i

  end

  # NEXT-705 - "All Fields" should be default, and should be first option
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

