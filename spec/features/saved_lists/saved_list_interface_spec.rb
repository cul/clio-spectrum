require 'spec_helper'

include Warden::Test::Helpers

describe 'Saved List Interface' do

  before(:each) do
    @autodidact = FactoryGirl.create(:user, login: 'autodidact')
    @blatteroon = FactoryGirl.create(:user, login: 'blatteroon')
  end

  it 'Capybara should let us login and logout and login again' do
    # Not yet logged in - navbar shows un-authenticated message
    visit catalog_index_path
    expect(find('#topnavbar')).to have_text 'My Library Account'

    # Login as the first user, verify the name shows in the nav bar
    feature_login @autodidact

    visit catalog_index_path
    expect(find('#topnavbar')).to have_text @autodidact.login

    # Logout - navbar shows un-authenticated message
    feature_logout
    visit catalog_index_path
    expect(find('#topnavbar')).to have_text 'My Library Account'

    # Login as the second user, verify the (second user's) name shows in the nav bar
    feature_login @blatteroon
    visit catalog_index_path
    expect(find('#topnavbar')).to have_text @blatteroon.login

    # Logout - navbar shows un-authenticated message
    feature_logout
    visit catalog_index_path
    expect(find('#topnavbar')).to have_text 'My Library Account'
  end

  it 'should give no access to anonymous users' do
    visit '/lists'
    # page.save_and_open_page # debug
    # page.should have_text('Login required to access Saved Lists')
    # In this context, the auth redirect happens against the local
    # server, giving a 404.
    # login_path = '/login'      # wind
    login_path = '/cas/login'  # cas
    expect(page).to have_text("Invalid URL: #{login_path}")

    visit '/saved_lists/1/edit'
    # page.save_and_open_page # debugI
    # page.should have_text('Login required to access Saved Lists')
    expect(page).to have_text("Invalid URL: #{login_path}")
  end

  it 'should protect private lists and share public lists', js: true do

    # Use Warden::Test::Helpers for Feature testing
    feature_login @autodidact

    # First, visit my Lists page.  Should see the default list, "Bookbag"
    visit '/lists'
    # page.save_and_open_page # debug
    expect(page).to have_text('Saved Lists')
    expect(page).to have_text('Bookbag')

    # Next, do a catalog search, Add all found items to our Bookbag
    visit catalog_index_path('q' => 'aardvark war')
    click_link('Selected Items')
    click_link('Select All Items')
    click_link('Selected Items')
    click_link('Add to My Saved List')

    # Now, go back again to my Lists page.  I should see the just-added records
    visit '/lists'
    # save_and_open_page # debug
    expect(page).to have_text('aardvark')

    # Move all these items off to a different named list
    click_link('Selected List Items')
    click_link('Select All Items')
    click_link('Move Selected Items')
    within('#new_list_form') do
      fill_in 'new_list_name', with: 'aardvark'
      click_button('new_list_submit')
    end
    # page.save_and_open_page # debug

    # We should be redirected to the new list, defaulting to private
    within('.savedlist_header') do
      expect(page).to have_text('aardvark')
      expect(page).to have_text('edit list details')
      first('span.label', text: 'private')
    end

    # Make this list public
    click_link 'edit list details'
    expect(page).to have_text('Editing list')
    choose('public')
    click_button 'Save'

    # Confirm that this change took affect.
    expect(page).to have_text('Saved Lists')
    within('.savedlist_header') do
      expect(page).to have_text('aardvark')
      expect(page).to have_text('edit list details')
      first('span.label', text: 'public')
    end

    # Next, do a new, different catalog search,
    # Add all found items to our Bookbag,
    # which should still be private
    visit catalog_index_path('q' => 'aardvark war')
    click_link('Selected Items')
    click_link('Select All Items')
    click_link('Selected Items')
    click_link('Add to My Saved List')

    # visit catalog_index_path()

    #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
    # # Login as a different user
    #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #

    feature_login @blatteroon
    visit catalog_index_path
    # save_and_open_page

    # Try to visit a non-existant list
    visit '/lists/NoSuchUser/NoSuchList'
    expect(page).to have_text('Cannot access list NoSuchUser/NoSuchList')

    # save_and_open_page # debug

    # # Try to edit a non-existant list
    # visit '/saved_lists/9999999/edit'
    # expect(page).to have_text('Cannot access list')

    # # Try to visit the first user's public list
    # visit "/lists/#{@audodidact.login}/aardvark"
    # within('.savedlist_header') do
    #   expect(page).to have_text('aardvark')
    #   first('span.label', :text => 'public')
    # end

    # # Try to visit the first user's private list
    # visit "/lists/#{@first_user_name}/bookbag"
    # expect(page).to have_text("Cannot access list #{@first_user_name}/bookbag")
    #

  end

  # This test triggers a file-download of the endnote file, then 
  # tries to interact with the webpage afterwards.
  # This fails with Capybara - When the file-download occurs, Capybara-Webkit 
  # loses the original webpage and loads the downloaded content instead.
  context "item can be added to bookbag after exporting to EndNote", selenium: true do

    it 'uses selenium driver' do
      expect(Capybara.current_driver).to be(:selenium)
    end

    it "adds to saved list afer EndNote export" do
      expect(Capybara.current_driver).to be(:selenium)
      visit catalog_path("4359539")
      login_as @blatteroon
      click_on('Export')
      click_on('Export to EndNote')
      click_on('Add to My Saved List')
      expect(page).to have_css(".alert", :text => "1 item added to list Bookbag")
    end
  # it "item can be added to bookbag after exporting to EndNote", js: true, type: :selenium do
  #   Capybara.current_driver = :selenium
  #   visit catalog_path("4359539")
  #   login_as @blatteroon
  #   click_link('Export')
  #   click_link('Export to EndNote')
  #   click_link('Add to My Saved List')
  #   expect(page).to have_css(".alert", :text => "1 item added to list Bookbag")
  end

end
