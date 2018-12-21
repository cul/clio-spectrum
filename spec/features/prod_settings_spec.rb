require 'spec_helper'

# We want to re-run an initializer file, over and over again,
# per environment.  Use 'load', not 'require', to allow this.  See:
#
#   http://ionrails.com/2009/09/19/ruby_require-vs-load-vs-include-vs-extend/
#
describe 'Prod Environment' do
  it 'Google Analytics has correct per-environment setting' do
    # should start as nil
    expect(GoogleAnalytics.web_property_id).to be_nil

    Rails.env = 'development'
    load File.join(Rails.root, 'config/initializers/google_analytics.rb')
    expect(GoogleAnalytics.web_property_id).to eq('UA-28923110-5')

    Rails.env = 'clio_dev'
    load File.join(Rails.root, 'config/initializers/google_analytics.rb')
    expect(GoogleAnalytics.web_property_id).to eq('UA-28923110-4')

    Rails.env = 'clio_test'
    load File.join(Rails.root, 'config/initializers/google_analytics.rb')
    expect(GoogleAnalytics.web_property_id).to eq('UA-28923110-3')

    Rails.env = 'clio_prod'
    load File.join(Rails.root, 'config/initializers/google_analytics.rb')
    expect(GoogleAnalytics.web_property_id).to eq('UA-28923110-1')

    # reset
    Rails.env = 'test'
  end
end
