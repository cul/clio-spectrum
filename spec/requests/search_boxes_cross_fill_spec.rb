require 'spec_helper'

describe "The home page" do
  it "will keep the text in a box across different sources on the landing pages", :js => true do
    visit catalog_index_path
    fill_in 'catalog_q', :with => 'test'
    sleep 1
    assert find('#articles_q').value == 'test'
  end

  it "will switch the visible search box when a datasource is clicked upon", :js => true do
    visit catalog_index_path
    assert find('#catalog_q').visible?
    assert !find('#articles_q').visible?
    find('li.datasource_link[source=articles]').click

    assert !find('#catalog_q').visible?
    assert find('#articles_q').visible?
  end
end

