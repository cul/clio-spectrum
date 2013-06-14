require "spec_helper"

describe ListsController do
  describe "routing" do

    it "routes to #index" do
      get("/lists").should route_to("lists#index")
    end

    it "routes to #new" do
      get("/lists/new").should route_to("lists#new")
    end

    it "routes to #show" do
      get("/lists/1").should route_to("lists#show", :id => "1")
    end

    it "routes to #edit" do
      get("/lists/1/edit").should route_to("lists#edit", :id => "1")
    end

    it "routes to #create" do
      post("/lists").should route_to("lists#create")
    end

    it "routes to #update" do
      put("/lists/1").should route_to("lists#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/lists/1").should route_to("lists#destroy", :id => "1")
    end

  end
end
