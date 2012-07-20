require "spec_helper"

describe Admin::DatabaseAlertsController do
  describe "routing" do

    it "routes to #index" do
      get("/admin_database_alerts").should route_to("admin_database_alerts#index")
    end

    it "routes to #new" do
      get("/admin_database_alerts/new").should route_to("admin_database_alerts#new")
    end

    it "routes to #show" do
      get("/admin_database_alerts/1").should route_to("admin_database_alerts#show", :id => "1")
    end

    it "routes to #edit" do
      get("/admin_database_alerts/1/edit").should route_to("admin_database_alerts#edit", :id => "1")
    end

    it "routes to #create" do
      post("/admin_database_alerts").should route_to("admin_database_alerts#create")
    end

    it "routes to #update" do
      put("/admin_database_alerts/1").should route_to("admin_database_alerts#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/admin_database_alerts/1").should route_to("admin_database_alerts#destroy", :id => "1")
    end

  end
end
