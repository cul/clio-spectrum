require 'spec_helper'

include Warden::Test::Helpers

describe "Saved List Interface" do

  before(:each) do
    @first_user_name = 'annie111'
    @user1 = FactoryGirl.create(:user, :login => @first_user_name)
    @second_user_name = 'betty222'
    @user2 = FactoryGirl.create(:user, :login => @second_user_name)
  end

  it "should give no access to anonymous users" do
    visit '/lists'
    # page.save_and_open_page # debug
    page.should have_text('Login required to access Saved Lists')

    visit '/saved_lists/1/edit'
    # page.save_and_open_page # debug
    page.should have_text('Login required to access Saved Lists')


  end

  it "should protect private lists and share public lists", :js => true, :XXfocus => true do

    feature_login @user1
    # valid_user_login @user1

    # First, visit my Lists page.  Should see the default list, "Bookbag"
    visit '/lists'
    # page.save_and_open_page # debug
    page.should have_text('Saved Lists')
    page.should have_text('Bookbag')

    # Next, do a catalog search, Add all found items to our Bookbag
    visit catalog_index_path('q' => 'aardvark war')
    click_link('Selected Items')
    click_link('Select All Items')
    click_link('Selected Items')
    click_link('Save to Bookbag')

    # Now, go back again to my Lists page.  I should see the just-added records
    visit '/lists'
    # page.save_and_open_page # debug
    page.should have_text('aardvark')
    
    # Move all these items off to a different named list
    click_link('Selected List Items')
    click_link('Select All Items')
    click_link('Move Selected Items')
    within('#new_list_form') do
      fill_in 'new_list_name', :with => 'aardvark'
      click_button('new_list_submit')
    end
    # page.save_and_open_page # debug
    
    # We should be redirected to the new list, defaulting to private
    within('.savedlist_header') do
      page.should have_text('aardvark')
      page.should have_text('edit list details')
      first('span.label', :text => 'private')
    end

    # Make this list public
    click_link "edit list details"
    page.should have_text('Editing list')
    choose('public')
    click_button "Save"

    # Confirm that this change took affect.
    page.should have_text('Saved Lists')
    within('.savedlist_header') do
      page.should have_text('aardvark')
      page.should have_text('edit list details')
      first('span.label', :text => 'public')
    end

    # Next, do a new, different catalog search, 
    # Add all found items to our Bookbag,
    # which should still be private
    visit catalog_index_path('q' => 'aardvark war')
    click_link('Selected Items')
    click_link('Select All Items')
    click_link('Selected Items')
    click_link('Save to Bookbag')

    # valid_user_logout
    #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
    
    # # Login as a different user
    # Rails.logger.debug("=========== LOGIN USER2 [#{@user2}]")
    # # feature_login @user2
    # valid_user_login @user2
    # 
    # Rails.logger.debug("=========== DONE")

    # Try to visit a non-existant list
    visit "/lists/NoSuchUser/NoSuchList"
    page.should have_text('Cannot access list NoSuchUser/NoSuchList')
    
    # page.save_and_open_page # debug
    
    # # Try to edit a non-existant list
    # visit '/saved_lists/9999999/edit'
    # page.should have_text('Cannot access list')
    # 
    # # Try to visit the first user's public list
    # visit "/lists/#{@first_user_name}/aardvark"
    # within('.savedlist_header') do
    #   page.should have_text('aardvark')
    #   first('span.label', :text => 'public')
    # end
    # 
    # # Try to visit the first user's private list
    # visit "/lists/#{@first_user_name}/bookbag"
    # page.should have_text("Cannot access list #{@first_user_name}/bookbag")
    # 
        

  end

end


