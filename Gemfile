source 'http://rubygems.org'
gem 'rails', '3.2.13'

gem 'sqlite3'

# Use unicorn as the web server
# gem 'unicorn'
gem 'thin'

gem 'blacklight', '>= 4.2.0'
gem 'blacklight_range_limit', :git => 'git://github.com/projectblacklight/blacklight_range_limit.git', :branch => 'master'
gem 'blacklight_google_analytics'
gem 'blacklight_unapi', ">= 0.0.3"
gem 'json'

# Called to produce status msgs. search result lists.
# This could be native to clio-spectrum, or put into Voyager-back-end
# gem 'voyager_oracle_api', ">= 1.1.1"

# Would be use for Patron services, if we were to use native blacklight Patron svcs.
# gem 'restful_voyage', :git => "git://github.com/cul/restful_voyage.git", :branch => "master"

group :clio_dev, :clio_test, :clio_prod do
  gem 'mysql2'
end

gem 'therubyracer', '0.10.2'
# Deploy with Capistrano
#gem 'newrelic_rpm'
gem 'has_options'
gem 'httpclient'
gem 'nokogiri'

# HTML replacement language
gem 'haml'
gem 'haml-rails'

# CSS replacement language
gem 'sass'
gem 'sass-rails', '~>3.2.4'

gem 'unicode'
gem 'summon'
gem 'cancan'

# Talks to Voyager API directly, return XML-format for Spectrum use.
# But, this is now used from within the Voyager-Backend application
# (which is now named cul/clio_backend up at github), and so
# this is no longer needed here within clio-spectrum.
# gem 'voyager_api', '>=0.2.3'

gem 'rubytree', '=0.5.2'

gem 'exception_notification'
gem 'net-ldap'

gem 'devise'
gem 'devise-encryptable'
gem 'devise_wind'

# marquis, 6/13 - javascript framework - unused?
# gem 'compass-rails'

gem 'jquery-rails'

group :assets do
  gem 'sass-rails', '~>3.2.4'
  gem 'coffee-rails', '~>3.2.2'
  gem 'uglifier', '>=1.0.3'
  gem 'bootstrap-sass', '~>2.1'
  # marquis, 6/13 - javascript framework - unused?
  # gem 'compass-rails'
  
  # marquis, 6/13 - coffeescript extensions - unused?
  # gem 'iced-rails'
end

gem 'newrelic_rpm'

# To build slugs for my-list URLs
gem 'stringex'

# Allow recovery for deleted Saved Lists 
gem 'paper_trail'

# To use debugger (ruby-debug for Ruby 1.8.7+, ruby-debug19 for Ruby 1.9.2+)

# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'

#group :development do
  #gem 'ruby-debug19', :require => 'ruby-debug'
  #gem 'rails-footnotes', '>= 3.7'
  #gem "rsolr-footnotes"
#end

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
# group :development, :test do
#   gem 'webrat'
# end
group :development do
  # marquis, 6/13 - currently, we're using thin for localhost development'
  # gem 'unicorn'
  # gem 'hooves'

  gem 'guard-rails'

  #gem 'linecache19', '0.5.13'
  #gem 'ruby-debug-base19', '0.11.26'
  #gem 'ruby-debug19', :require => 'ruby-debug'
  gem 'capistrano'
  gem 'capistrano-ext'
  gem 'quiet_assets'
  
# http://railscasts.com/episodes/402-better-errors-railspanel
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'
end

group :test, :development do
  gem 'rspec-rails'
  # marquis, 6/13 - we're not using desktop growl, so don't load the gem
  # gem "growl"
  # ditto.  "growl notification transport protocol"
  # gem 'ruby_gntp'
  gem 'rb-fsevent'
  gem 'ruby-prof'
end

group :test do
  gem 'factory_girl_rails'
  gem 'spork', '~>1.0.0.rc2'
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-spork'
  gem 'rspec-rails'
  # gem 'capybara'
  gem 'capybara', '2.0.3'
  gem 'capybara-webkit'
  gem 'launchy'
  gem 'database_cleaner'
end
