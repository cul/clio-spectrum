require 'spec_helper'

describe SpectrumController do

  describe "GET 'search'" do
    it "returns http success" do
      get 'search'
      response.should be_success
    end

    it "redirects on bad input" do
      get 'search', :q => 'dummy', :layout => 'No Such Layout'
      response.status.should be(302)
      response.should redirect_to(root_path)
      flash[:error].should =~ /no search layout/i
    end
  end

  describe "GET 'fetch'" do
    it "returns http success" do
      get 'fetch', :layout => 'qucksearch', :datasource => 'catalog'
      response.should be_success
    end

    it "errors on bad input" do
      get 'fetch', :layout => 'No Such Layout', :datasource => 'catalog'
      response.should be_success
      response.body.should =~ /search layout invalid/i
    end
  end

  # describe 'getting results from invalid source' do
  #   it 'should error appropriately' do
  #     SpectrumController#get_results(12)
  #   end
  # end


  # it "should raise RuntimeError if invalid datasource passed" do
  #   expect {
  #     SpectrumController.get_results( ['NoSuchDatasource'] )
  #   }.to raise_error(RuntimeError)
  # end


end
