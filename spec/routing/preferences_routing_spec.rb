require "rails_helper"

RSpec.describe PreferencesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/preferences").to route_to("preferences#index")
    end

    it "routes to #new" do
      expect(:get => "/preferences/new").to route_to("preferences#new")
    end

    it "routes to #show" do
      expect(:get => "/preferences/1").to route_to("preferences#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/preferences/1/edit").to route_to("preferences#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/preferences").to route_to("preferences#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/preferences/1").to route_to("preferences#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/preferences/1").to route_to("preferences#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/preferences/1").to route_to("preferences#destroy", :id => "1")
    end

  end
end
