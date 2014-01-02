require 'spec_helper'

describe "The home page" do
  it "will keep the text in a box across different sources on the landing pages", :js => true do
    visit catalog_index_path
    fill_in 'catalog_q', :with => 'test'
    sleep 1
    find('#articles_q',  visible: false).value.should == 'test'
  end

  it "will switch the visible search box when a datasource is clicked upon", :js => true do
    visit catalog_index_path

    find('#catalog_q').should be_visible
    # find('#articles_q').should_not be_visible
    page.should have_no_selector('#articles_q')

    find('li.datasource_link[source=articles]').click

    # find('#catalog_q').should_not be_visible
    page.should have_no_selector('#catalog_q')
    find('#articles_q').should be_visible
  end
end

