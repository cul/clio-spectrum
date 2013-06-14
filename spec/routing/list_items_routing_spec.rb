require "spec_helper"

describe ListItemsController do
  describe "routing" do

    it "routes to #index" do
      get("/list_items").should route_to("list_items#index")
    end

    it "routes to #new" do
      get("/list_items/new").should route_to("list_items#new")
    end

    it "routes to #show" do
      get("/list_items/1").should route_to("list_items#show", :id => "1")
    end

    it "routes to #edit" do
      get("/list_items/1/edit").should route_to("list_items#edit", :id => "1")
    end

    it "routes to #create" do
      post("/list_items").should route_to("list_items#create")
    end

    it "routes to #update" do
      put("/list_items/1").should route_to("list_items#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/list_items/1").should route_to("list_items#destroy", :id => "1")
    end

  end
end
