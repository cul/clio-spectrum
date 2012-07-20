require "spec_helper"

describe DatabaseAlertsController do
  describe "routing" do

    it "routes to #index" do
      get("/database_alerts").should route_to("database_alerts#index")
    end

    it "routes to #new" do
      get("/database_alerts/new").should route_to("database_alerts#new")
    end

    it "routes to #show" do
      get("/database_alerts/1").should route_to("database_alerts#show", :id => "1")
    end

    it "routes to #edit" do
      get("/database_alerts/1/edit").should route_to("database_alerts#edit", :id => "1")
    end

    it "routes to #create" do
      post("/database_alerts").should route_to("database_alerts#create")
    end

    it "routes to #update" do
      put("/database_alerts/1").should route_to("database_alerts#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/database_alerts/1").should route_to("database_alerts#destroy", :id => "1")
    end

  end
end
