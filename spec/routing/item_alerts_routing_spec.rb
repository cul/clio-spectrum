require "spec_helper"

describe ItemAlertsController do
  describe "routing" do

    it "routes to #index" do
      get("/item_alerts").should route_to("item_alerts#index")
    end

    it "routes to #new" do
      get("/item_alerts/new").should route_to("item_alerts#new")
    end

    it "routes to #show" do
      get("/item_alerts/1").should route_to("item_alerts#show", :id => "1")
    end

    it "routes to #edit" do
      get("/item_alerts/1/edit").should route_to("item_alerts#edit", :id => "1")
    end

    it "routes to #create" do
      post("/item_alerts").should route_to("item_alerts#create")
    end

    it "routes to #update" do
      put("/item_alerts/1").should route_to("item_alerts#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/item_alerts/1").should route_to("item_alerts#destroy", :id => "1")
    end

  end
end
