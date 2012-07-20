require 'spec_helper'

describe "Admin::DatabaseAlerts" do
  describe "GET /admin_database_alerts" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get admin_database_alerts_path
      response.status.should be(200)
    end
  end
end
