require 'spec_helper'

describe 'database_routing', :type => "request" do 
  include Rails.application.routes.url_helpers 

  before do
  end

  it 'routes the database_index properly' do
    puts "Capybara.default_host: #{Capybara.default_host}"
    puts "some_app_url: #{catalog_path}"
    visit("/catalog?q=test")
  end
end
