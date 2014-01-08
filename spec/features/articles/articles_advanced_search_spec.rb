require 'spec_helper'


describe "Articles Search" do

  # NEXT-581 - Articles Advanced Search should include Publication Title search
  # NEXT-793 - add Advanced Search to Articles, support Publication Title search
  it "should let you perform an advanced publication title search", :js => true do
    visit root_path
    find('li.datasource_link[source=articles]').click
    find('#articles_q').should be_visible
    page.should have_no_selector('.landing_page.articles .advanced_search')
    # find('.landing_page.articles .advanced_search').should_not be_visible


    find('.search_box.articles .advanced_search_toggle').click
    find('.landing_page.articles .advanced_search').should be_visible
    within '.landing_page.articles .advanced_search' do
      fill_in 'publicationtitle', :with => "test"

      find('button[type=submit]').click()

    end

    find(".well-constraints").should have_content('Publication Title')
  end


  # NEXT-622 - Basic Articles Search should have a pull-down for fielded search
  # NEXT-842 - Articles search results page doesn't put search term back into search box
  it "should let you perform a fielded search from the basic search", :js => true do
    visit articles_index_path
    within '.search_box.articles' do
      find('#articles_q').should be_visible
      fill_in 'q', :with => "catmull, ed"
      find('btn.dropdown-toggle').click()
      within '.dropdown-menu' do
        find("a[data-value='s.fq[AuthorCombined]']").click()
      end
      find('button[type=submit]').click()
    end

    # Search string and search field should be preserved
    find("#articles_q").value.should eq 'catmull, ed'
    find('.btn.dropdown-toggle').should have_content('Author')

    # The entered fielded search should be echoed on the results page
    find(".well-constraints").should have_content('Author: catmull, ed')

    # And the search results too
    find('#documents').should have_content('Author Catmull')

    # AND, add in some test related to pub-date sorting...

    # page.save_and_open_page # debug

    first('.index_toolbar').should have_content("Sort by Relevance")
    first(:link, 'Sort by Relevance').click

    find_link('Relevance')
    find_link('Published Latest')
    find_link('Published Earliest').click

    first('.index_toolbar').should have_content("Published Earliest")
    first(:link, 'Published Earliest').click
    find_link('Relevance')
    find_link('Published Earliest')
    find_link('Published Latest').click

    first('.index_toolbar').should have_content("Published Latest")
    first(:link, 'Published Latest').click
    find_link('Relevance')
    find_link('Published Earliest')
    find_link('Published Latest')
  end

end

