source 'http://rubygems.org'

# Can't move up to 4.0 series yet - blacklight_range_limit has dependency on 3
gem 'rails', '3.2.14'
# gem 'rails', '~> 4.0.0'

gem 'sqlite3'

# Use unicorn as the web server
# gem 'unicorn'
gem 'thin'

gem 'blacklight', '~>4.2.0'
gem 'blacklight_range_limit', :git => 'git://github.com/projectblacklight/blacklight_range_limit.git', :branch => 'master'
gem 'blacklight_google_analytics'

# Sorry, have to nix unapi.  Switch to COINS everywhere, so that
# single page cross-datasource citation works (QuickSearch, Saved Lists)
# gem 'blacklight_unapi', ">= 0.0.3"

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


# application monitoring tool
gem 'newrelic_rpm'

# marquis, 6/13 - javascript framework - unused?
# gem 'compass-rails'

gem 'jquery-rails'

group :assets do
  gem 'sass-rails', '~>3.2.4'
  gem 'coffee-rails', '~>3.2.2'
  gem 'uglifier', '>=1.0.3'
  gem 'bootstrap-sass', '~>2.1'

  # marquis, 6/13 - unused?
  # gem 'compass-rails'
end


# To build slugs for saved-list URLs
gem 'stringex'

# Allow recovery for deleted Saved Lists
gem 'paper_trail'

# https://github.com/kickstarter/rack-attack
# A DSL for blocking & throttling abusive clients
gem 'rack-attack'

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
  gem 'guard-rails'

  # alternative webserver
  # gem 'hooves'
  # gem 'unicorn'

  #gem 'linecache19', '0.5.13'
  #gem 'ruby-debug-base19', '0.11.26'
  #gem 'ruby-debug19', :require => 'ruby-debug'
  gem 'capistrano'
  gem 'capistrano-ext'
  gem 'quiet_assets'

  # browser-based live debugger and REPL
  # http://railscasts.com/episodes/402-better-errors-railspanel
  gem 'better_errors'
  gem 'binding_of_caller'
  # is this what's slowing us down so much?
  # gem 'meta_request'

  # port of ruby-debug that works on 1.9.2 and 1.9.3
  gem 'debugger'
end

group :test, :development do

end

group :test do
  gem 'factory_girl_rails'
  gem 'spork', '~>1.0.0.rc2'

  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-spork'
  
  # pin to old version, or go with newest?
  gem 'capybara'
  # gem 'capybara', '2.0.3'
  
  # Which Capybara driver for JS support?
  gem 'capybara-webkit'
  # dependent on localhost's browser configs
  # gem 'selenium-webdriver'  
  
  gem 'launchy'
  gem 'database_cleaner'
  # Mac OS X 10.8 (Mountain Lion) Notifications replace growl
  # http://protips.maxmasnick.com/mountain-lion-notifications-with-guard
  # gem "growl"
  gem 'terminal-notifier-guard'

  gem 'rspec-rails', '>=2.14'

  gem 'rb-fsevent'
  # GNTP is Growl's protocol - turn off, since no more Growl
  # gem 'ruby_gntp'
  gem 'ruby-prof'


  # code coverage
  gem 'simplecov'
end
