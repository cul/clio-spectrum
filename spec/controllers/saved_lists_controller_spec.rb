require 'spec_helper'

describe SavedListsController do

  before(:each) do
    @first_user_name = 'user_alpha'
    @first_user = FactoryBot.create(:user, login: @first_user_name)
    @second_user_name = 'user_beta'
    @second_user = FactoryBot.create(:user, login: @second_user_name)
  end

  it "anonymous users can't do much" do
    delete :destroy,  id: 1
    # page.save_and_open_page # debug
    expect(response.status).to be(302)
    # Can't figure this out....
    # expect(response).to redirect_to location: 'http://wind.columbia.edu/login'
    # expect(response).to redirect_to %r(\Ahttp://wind.columbia.edu/login)

    put :update,  id: 1
    # page.save_and_open_page # debug
    expect(response.status).to be(302)
    # Can't figure this out....
    # expect(response).to redirect_to %r(\Ahttp://wind.columbia.edu/login)
  end

  it 'authenticated users can interact...' do

    # use Devise::Test::ControllerHelpers methods for Controller tests
    # sign_in :user, @first_user
    spec_login @first_user

    # Try to delete a non-existant list
    delete :destroy,  id: 9_999_999
    expect(response.status).to be(302)
    expect(response).to redirect_to(root_path)
    expect(flash[:error]).to match(/Cannot access list/i)

    # Try to update a non-existant list
    put :update,  id: 9_999_999
    expect(response.status).to be(302)
    expect(response).to redirect_to(root_path)
    expect(flash[:error]).to match(/Cannot access list/i)
  end

end
