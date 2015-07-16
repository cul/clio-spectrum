require 'spec_helper'

describe SpectrumController do

  describe "GET 'search'" do
    it 'returns http success' do
      get 'search'
      expect(response).to be_success
    end

    it 'redirects on bad input' do
      get 'search', q: 'dummy', layout: 'No Such Layout'
      expect(response.status).to be(302)
      expect(response).to redirect_to(root_path)
      expect(flash[:error]).to match(/no search layout/i)
    end
  end

  describe "GET 'fetch'" do
    it 'returns http success' do
      get 'fetch', layout: 'qucksearch', datasource: 'catalog'
      expect(response).to be_success
    end

    it 'errors on bad input' do
      get 'fetch', layout: 'No Such Layout', datasource: 'catalog'
      expect(response).to be_success
      expect(response.body).to match(/search layout invalid/i)
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

  # BROKEN
  # need to call private function,
  # with input arguments,
  # and support a call to Rails params()
  #
  # describe SpectrumController do
  #
  #   it "should raise RuntimeError if invalid datasource passed" do
  #     # helper.stub!(:params).and_return {}
  #     sc = SpectrumController.new()
  #     sc.stub!(:params).and_return {}
  #     expect {
  #       sc.send(:get_results,  ['NoSuchDatasource'])
  #     }.to raise_error(RuntimeError)
  #   end
  #
  #
  # end

end
