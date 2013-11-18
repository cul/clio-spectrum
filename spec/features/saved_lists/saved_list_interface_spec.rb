require 'spec_helper'

include Warden::Test::Helpers

describe "Saved List Interface" do

  before(:each) do
    @first_user_name = 'user_alpha'
    @first_user = FactoryGirl.create(:user, :login => @first_user_name)
    @second_user_name = 'user_beta'
    @second_user = FactoryGirl.create(:user, :login => @second_user_name)
  end

  it "should protect private lists and share public lists", :js => true do

    login @first_user

    visit '/lists'
    # page.save_and_open_page # debug
    page.should have_text('Saved Lists')
    page.should have_text('Bookbag')

    visit catalog_index_path('q' => 'aardvark war')
    click_link('Selected Items')
    click_link('Select All Items')

    click_link('Selected Items')
    click_link('Save to Bookbag')

    # page.save_and_open_page # debug

    visit '/lists'
    # page.save_and_open_page # debug
    page.should have_text('aardvark')

    click_link "edit list details"
    choose('public')
    click_button "Save"

    page.should have_text('Saved Lists')
    page.should have_text('Bookbag')
    first('span.label', :text => 'public')

    login @second_user
    visit "/lists/#{@first_user_name}/bookbag"
    page.should have_text('aardvark')

  end

end


