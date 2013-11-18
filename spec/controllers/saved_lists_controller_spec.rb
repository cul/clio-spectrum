require 'spec_helper'

describe SavedListsController do

  it "redirects on bad input" do
    owner = "owner-#{DateTime.now.to_s}"
    list = "list-#{DateTime.now.to_s}"
    get "/lists/#{owner}/#{list}"
    response.status.should be(302)
    response.should redirect_to(root_path)

    message = "Cannot access list #{owner}.#{list}"
    flash[:error].should =~ /message/i
  end

end




