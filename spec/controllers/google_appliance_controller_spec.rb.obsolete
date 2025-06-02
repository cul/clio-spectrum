require 'spec_helper'

describe Spectrum::SearchEngines::GoogleAppliance do
  it "should raise RuntimeError if no 'q' param passed" do
    expect do
      Spectrum::SearchEngines::GoogleAppliance.new
    end.to raise_error(RuntimeError)
  end

  it 'should set @errors and return nothing on search errors' do
    # First, should be no errors
    ga = Spectrum::SearchEngines::GoogleAppliance.new('q' => 'english')
    expect(ga.errors).to be_nil

    # Set our GA URL to an unroutable IP...
    saved_ga_url = APP_CONFIG['google_appliance_url']
    APP_CONFIG['google_appliance_url'] = 'http://999.999.999.999'

    # Then, with a bad backend URL, there should be errors
    ga = Spectrum::SearchEngines::GoogleAppliance.new('q' => 'math')
    expect(ga.errors).to_not be_nil

    # Restore our real GA URL so that subsequent tests work
    APP_CONFIG['google_appliance_url'] = saved_ga_url
  end
end
