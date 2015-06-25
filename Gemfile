source 'https://rubygems.org'

# FIXED:  Can't move up to 4.0 series yet - blacklight_range_limit has dependency on 3
# but, devise_wind still has Rails 3.2 dependencies.
gem 'rails', '~> 3.2'
# gem 'rails', '~> 4.0.0'


#  ###  BLACKLIGHT (begin)  ###

gem 'blacklight', '~>5.9.0'

# when we move to 5.x, uncomment this
gem 'blacklight-marc'

# gem 'blacklight_range_limit', :git => 'git://github.com/projectblacklight/blacklight_range_limit.git', :tag => 'v2.1.0'

gem 'blacklight_range_limit', :git => 'git://github.com/projectblacklight/blacklight_range_limit.git', :branch => 'master'

#  ###  BLACKLIGHT (end)  ###


# Only used for Google Maps location pages
gem 'rest-client'
gem 'gmaps4rails'

# pagination
gem 'kaminari'

# pull from rubygems...
# gem 'devise_wind'
# Local copy relaxes rails version requirements (allows 4.x)
# gem "devise_wind", :path => "/Users/marquis/src/devise_wind"
# New branch to recover from when CUIT broke wind
gem "devise_wind", :git => 'git://github.com/cul/devise_wind.git', :branch => 'broke_wind'


# Not being used, turn it off.
# # Locally developed library code to interface with ClickTale analytics
# gem 'clicktale', path: "lib/clicktale"

gem 'json'

# Always include sqlite, deploy to all servers, so that we can use dummy databases
#  for simplified rails environments used in index rake cronjobs
gem 'sqlite3'

group :clio_dev, :clio_test, :clio_prod do
  gem 'mysql2'
end

# Some things we want to see in development and in-action on 
# the LERP servers, but not in production.
group :development, :clio_dev do

  # "MiniProfiler allows you to see the speed of a request on the page"
  # http://railscasts.com/episodes/368-miniprofiler
# Disable while we straighten out the Bootstrap 3 style issues.
  # gem 'rack-mini-profiler'

end


# "Associates a hash of options with an ActiveRecord model"
# Used for... apparently, just the list of links for each location?
# locally developed - and no longer on Github...
# should try to eliminate at some point.
gem 'has_options'

gem 'therubyracer'
gem 'httpclient'
gem 'nokogiri'

# HTML replacement language
gem 'haml'
gem 'haml-rails'

# CSS replacement language
gem 'sass'

# are we using this anywhere?
# gem 'unicode'

# fork local branch, to add network timeouts
# gem 'summon'
gem 'summon', :git => 'git://github.com/cul/summon.git'
# Point to local copy during development...
# gem 'summon', :path => "/Users/marquis/src/summon"

# auth library
gem 'cancan'

# doesn't work in Rails 4 ??
# RecordMailer uses partials that do fragment caching... but somehow
# this just doesn't work in stock rails.
gem 'caching_mailer'

gem 'exception_notification'
gem 'net-ldap'

gem 'devise'
gem 'devise-encryptable'


# "Rack middleware which cleans up invalid UTF8 characters"
gem 'rack-utf8_sanitizer'

# gives us jQuery and jQuery-ujs, but not jQuery UI
# (blacklight_range_limit brings this in anyway - no way to switch to CDN)
gem 'jquery-rails'

# # jQuery UI - JavaScript, CSS, Images
# gem 'jquery-ui-rails'

group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier'
  gem 'bootstrap-sass'
end


# To build slugs for saved-list URLs
gem 'stringex'

# Allow recovery for deleted Saved Lists
gem 'paper_trail'

# I seriously have to do this?
gem 'rack'

# https://github.com/kickstarter/rack-attack
# A DSL for blocking & throttling abusive clients
gem 'rack-attack'


# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development do

  # Deploy with Capistrano
  gem 'capistrano', '~>2', :require => false
  gem 'capistrano-ext', :require => false
  gem 'quiet_assets'
  # fixes [morrison.cul.columbia.edu] sh: bundle: command not found
  gem 'rvm-capistrano', :require => false

  # browser-based live debugger and REPL
  # http://railscasts.com/episodes/402-better-errors-railspanel
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'

  # Trouble building on Yosemite 10.10, and since 
  # I don't use it, remove it.
  # # port of ruby-debug that works on 1.9.2 and 1.9.3
  # gem 'debugger'

  # "A fist full of code metrics"
  # gem 'metric_fu'

  # Profiling experiments
  # https://www.coffeepowered.net/2013/08/02/ruby-prof-for-rails/
  # gem 'request_profiler', :git => "git://github.com/justinweiss/request_profiler.git"

end

group :test, :development do

  gem 'thin'

  # why in test and dev both instead of just test?  
  # because is says to: https://github.com/rspec/rspec-rails
  gem 'rspec-rails'
end

group :test do
  gem 'factory_girl_rails'

  # Copy Stanford's approach to Solr relevancy testing
  gem 'rspec-solr'

  # pin to old version, or go with newest?
  gem 'capybara'

  # Which Capybara driver for JS support?
  gem 'capybara-webkit'

  # dependent on localhost's browser configs
  gem 'selenium-webdriver'

  # "A helper for launching cross-platform applications 
  #  in a fire and forget manner."
  # Required to enable capybara's save_and_open_page() method
  gem 'launchy'

  # reset database tables between test runs
  gem 'database_cleaner'

  gem 'rb-fsevent'

  # Not doing anything with profiling just now, but when we get back to it,
  # reread:   https://www.coffeepowered.net/2013/08/02/ruby-prof-for-rails/
  # gem 'ruby-prof'

  # code coverage
  gem 'simplecov'

  # CI servers want XML output from rspecs
  # gem 'ci_reporter'
  
end
