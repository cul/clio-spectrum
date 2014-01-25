require 'spec_helper'

describe "The home page" do

  # This behavior was eliminated when we switched to static
  # links between datasources.  "q" values are caried between
  # data-sources, but not text that's been entered in the gui
  # and not-yet used to search.
  
  # it "will keep the text in a box across different sources on the landing pages", :js => true do
  #   visit catalog_index_path
  #   fill_in 'catalog_q', :with => 'test'
  #   sleep 1
  #   find('#articles_q',  visible: false).value.should == 'test'
  # end

  it "will switch the visible search box when a datasource is clicked upon", :js => true do
    visit catalog_index_path

    find('#catalog_q').should be_visible
    page.should have_no_selector('#articles_q')

    within('li.datasource_link[source=articles]') do
      click_link('Articles')
    end

    page.should have_no_selector('#catalog_q')
    find('#articles_q').should be_visible
  end
end

