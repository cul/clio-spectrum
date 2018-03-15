require 'spec_helper'

# require 'database_cleaner'

# DatabaseCleaner.strategy = :truncation

describe SavedListsController do

  before(:each) do
    # DatabaseCleaner.clean
    User.delete_all
    @first_user_name = 'user_alpha'
    @first_user = FactoryBot.create(:user, login: @first_user_name)
  end
  
  # after(:all) do
  #   DatabaseCleaner.clean
  # end

  it "anonymous users can't do much" do
    delete :destroy,  params: { id: 1 }
    # page.save_and_open_page # debug
    expect(response.status).to be(302)
    # Can't figure this out....
    # expect(response).to redirect_to location: 'http://wind.columbia.edu/login'
    # expect(response).to redirect_to %r(\Ahttp://wind.columbia.edu/login)

    put :update,  params: { id: 1 }
    # page.save_and_open_page # debug
    expect(response.status).to be(302)
    # Can't figure this out....
    # expect(response).to redirect_to %r(\Ahttp://wind.columbia.edu/login)
  end

  it 'authenticated users can interact...' do
    spec_login @first_user

    # Try to delete a non-existant list
    delete :destroy,  params: { id: 9_999_999 }
    expect(response.status).to be(302)
    expect(response).to redirect_to(root_path)
    expect(flash[:error]).to match(/Cannot access list/i)

    # Try to update a non-existant list
    put :update,  params: { id: 9_999_999 }
    expect(response.status).to be(302)
    expect(response).to redirect_to(root_path)
    expect(flash[:error]).to match(/Cannot access list/i)
  end

end
