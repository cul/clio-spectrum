require 'spec_helper'


describe BackendController do
  # BackendController doesn't have an interface that can be excercised
  #  with feature tests.  We'll test html content here with controller
  #  specs although we maybe should setup request-specs for this.
  render_views

  before(:all) do
    APP_CONFIG['saved_backend_url'] = APP_CONFIG['clio_backend_url']
  end

  after(:all) do
    APP_CONFIG['clio_backend_url'] = APP_CONFIG['saved_backend_url']
  end

  # NEXT-1009 - Multiple 866 fields in the holding records
  it "holdings with multiple 866s" do
    get 'holdings', :id => '763577'
    response.should be_success
    response.body.should_not match /\-\-/
    response.body.should match /<br\/>Special issues/
  end


  # NEXT-988 - Label the Call Number field
  it "should label Call Numbers", :focus => true do
    # Simple case
    get 'holdings', :id => '123456'
    response.should be_success
    response.body.should match /Call Number:\s+HD1945/m

    # Complex case
    get 'holdings', :id => '763577'
    response.should be_success
    response.body.should match /Call Number:\s+R341.273/m
    response.body.should match /Call Number:\s+JX233/m
    response.body.should match /Call Number:\s+MICFICHE/m
  end

  it "holdings() should silently ignore a bad CLIO ID" do

    # non-numeric value
    get 'holdings', :id => 'non-numeric'
    response.should be_success
    response.body.strip.should be_empty

    # really, really big integer
    get 'holdings', :id => '999999999999999999999999999999999999'
    response.should be_success
    response.body.strip.should be_empty

  end


  it "should refuse to route without an ID filled in" do

    expect {
      # nil
      get 'holdings', :id => nil
    }.to raise_error(ActionController::RoutingError)

    expect {
      # nil
      get 'holdings'
    }.to raise_error(ActionController::RoutingError)

  end

  it "holdings() should silently absorb 404 from clio_backend_url" do
    APP_CONFIG['clio_backend_url'] = APP_CONFIG['clio_backend_url'] + "/foo/bar"
    get 'holdings', :id => '123'
    response.should be_success
    response.body.strip.should be_empty
  end



  it "holdings() should silently absorb a bogus clio_backend_url" do
    APP_CONFIG['clio_backend_url'] = 'http://no.such.host'
    get 'holdings', :id => '123'
    response.should be_success
    response.body.strip.should be_empty
  end


  it "holdings() should silently absorb unroutable clio_backend_url" do
    APP_CONFIG['clio_backend_url'] = 'http://10.0.0.1'
    get 'holdings', :id => '123'
    response.should be_success
    response.body.strip.should be_empty
  end

  it "url_for_id() should raise RuntimeError if when clio_backend_url unset" do
    expect {
      be = BackendController.new()
      APP_CONFIG.delete('clio_backend_url')
      be.url_for_id(123)
    }.to raise_error(RuntimeError)
  end



end



