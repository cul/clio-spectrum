require 'spec_helper'

describe SavedListsController do

  before(:each) do
    @first_user_name = 'user_alpha'
    @first_user = FactoryGirl.create(:user, :login => @first_user_name)
    @second_user_name = 'user_beta'
    @second_user = FactoryGirl.create(:user, :login => @second_user_name)
  end


  it "anonymous users can't do much" do
    delete :destroy,  :id => 1
    # page.save_and_open_page # debug
    response.status.should be(302)
    response.should redirect_to(root_path)
    flash[:error].should =~ /Login required to access Saved Lists/i

    put :update,  :id => 1
    # page.save_and_open_page # debug
    response.status.should be(302)
    response.should redirect_to(root_path)
    flash[:error].should =~ /Login required to access Saved Lists/i
  end

  it "authenticated users can interact..." do

    login @first_user

    # Try to delete a non-existant list
    delete :destroy,  :id => 9999999
    response.status.should be(302)
    response.should redirect_to(root_path)
    flash[:error].should =~ /Cannot access list/i

    # Try to update a non-existant list
    put :update,  :id => 9999999
    response.status.should be(302)
    response.should redirect_to(root_path)
    flash[:error].should =~ /Cannot access list/i
  end

end




