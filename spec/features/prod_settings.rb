require 'spec_helper'


describe 'Prod Environment' do

  it "Google Analytics setting" do
    # should start as nil
    BlacklightGoogleAnalytics.web_property_id.should be_nil

    # should have correct production value
    Rails.env = 'clio_prod'
    require File.join(Rails.root, "config/initializers/blacklight_google_analytics.rb")
    BlacklightGoogleAnalytics.web_property_id.should == 'UA-28923110-1'

    
  end

end

