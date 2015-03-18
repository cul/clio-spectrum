require 'spec_helper'

describe ApplicationController, type: :controller do

  describe 'Browser Options Set/Get' do

    it 'should fail appropriately' do

      # Calling "set" without both name and value is a bad request (400)

      get :set_browser_option_handler
      expect(response).not_to be_success
      expect(response.status).to be(400)

      get :set_browser_option_handler, name: 'foo'
      expect(response).not_to be_success
      expect(response.status).to be(400)

      get :set_browser_option_handler, value: 'bar'
      expect(response).not_to be_success
      expect(response.status).to be(400)

      # Calling "get" with a value, or without a name, is a bad request (400)

      get :get_browser_option_handler
      expect(response).not_to be_success
      expect(response.status).to be(400)

      get :get_browser_option_handler, name: 'foo', value: 'bar'
      expect(response).not_to be_success
      expect(response.status).to be(400)

      get :get_browser_option_handler, value: 'bar'
      expect(response).not_to be_success
      expect(response.status).to be(400)

      # new, unique name should not be found (404)
      name = "name__#{DateTime.now.to_s}"
      get :get_browser_option_handler, name: name
      expect(response).not_to be_success
      expect(response.status).to be(404)

    end

    it 'should persist data' do
      # bild a new, unique, name and value pair
      name = "name__#{DateTime.now.to_s}"
      value = "value__#{DateTime.now.to_s}"

      get :set_browser_option_handler, name: name, value: value
      expect(response).to be_success

      get :get_browser_option_handler, name: name
      expect(response).to be_success
      expect(response.header['Content-Type']).to match(/application\/json/)
      expect(response.body).to eq(value)
    end

  end

end
