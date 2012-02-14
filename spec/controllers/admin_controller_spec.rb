require 'spec_helper'

describe AdminController do

  describe "GET 'ingest_log'" do
    it "returns http success" do
      get 'ingest_log'
      response.should be_success
    end
  end

end
