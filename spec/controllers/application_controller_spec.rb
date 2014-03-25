require 'spec_helper'

describe ApplicationController do

  describe 'Browser Options Set/Get' do

    it 'should fail appropriately' do

      # Calling "set" without both name and value is a bad request (400)

      get :set_browser_option_handler
      response.should_not be_success
      response.status.should be(400)

      get :set_browser_option_handler, name: 'foo'
      response.should_not be_success
      response.status.should be(400)

      get :set_browser_option_handler, value: 'bar'
      response.should_not be_success
      response.status.should be(400)

      # Calling "get" with a value, or without a name, is a bad request (400)

      get :get_browser_option_handler
      response.should_not be_success
      response.status.should be(400)

      get :get_browser_option_handler, name: 'foo', value: 'bar'
      response.should_not be_success
      response.status.should be(400)

      get :get_browser_option_handler, value: 'bar'
      response.should_not be_success
      response.status.should be(400)

      # new, unique name should not be found (404)
      name = "name__#{DateTime.now.to_s}"
      get :get_browser_option_handler, name: name
      response.should_not be_success
      response.status.should be(404)

    end

    it 'should persist data' do
      # bild a new, unique, name and value pair
      name = "name__#{DateTime.now.to_s}"
      value = "value__#{DateTime.now.to_s}"

      get :set_browser_option_handler, name: name, value: value
      response.should be_success

      get :get_browser_option_handler, name: name
      response.should be_success
      response.header['Content-Type'].should include 'application/json'
      response.body.should == value
    end

  end

end
