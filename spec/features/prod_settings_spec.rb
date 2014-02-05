require 'spec_helper'


describe 'Prod Environment' do

  it "Google Analytics setting" do
    # should start as nil
    BlacklightGoogleAnalytics.web_property_id.should be_nil

    # should have correct values per environment

    Rails.env = 'development'
    require File.join(Rails.root, "config/initializers/google_analytics.rb")
    BlacklightGoogleAnalytics.web_property_id.should == 'UA-28923110-4'

    # should have correct values per environment
    Rails.env = 'clio_dev'
    require File.join(Rails.root, "config/initializers/google_analytics.rb")
    BlacklightGoogleAnalytics.web_property_id.should == 'UA-28923110-4'

    # should have correct values per environment
    Rails.env = 'clio_test'
    require File.join(Rails.root, "config/initializers/google_analytics.rb")
    BlacklightGoogleAnalytics.web_property_id.should == 'UA-28923110-3'

    # should have correct values per environment
    Rails.env = 'clio_prod'
    require File.join(Rails.root, "config/initializers/google_analytics.rb")
    BlacklightGoogleAnalytics.web_property_id.should == 'UA-28923110-1'
  end

end

