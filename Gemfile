source 'https://rubygems.org'

# FIXED:  Can't move up to 4.0 series yet - blacklight_range_limit has dependency on 3
# but, devise_wind still has Rails 3.2 dependencies.
gem 'rails', '~> 3.2'
# gem 'rails', '~> 4.0.0'


#  ###  BLACKLIGHT (begin)  ###

gem 'blacklight', '~>5.3.0'
# gem 'blacklight', '~>4.7.0'
# gem 'blacklight', '~>4'

# when we move to 5.x, uncomment this
gem 'blacklight-marc'

gem 'rest-client'
gem 'gmaps4rails'
# We already have a minified version of underscore
# installed directly in our assets directory,
# don't need this gem also.
# gem 'underscore-rails', '~> 1.7.0'

# gem 'blacklight_range_limit', :git => 'git://github.com/projectblacklight/blacklight_range_limit.git', :tag => 'v2.1.0'

gem 'blacklight_range_limit', :git => 'git://github.com/projectblacklight/blacklight_range_limit.git', :branch => 'master'

# gem 'blacklight_range_limit', :github => 'projectblacklight/blacklight_range_limit'

# Sorry, have to nix unapi.  Switch to COINS everywhere, so that
# single page cross-datasource citation works (QuickSearch, Saved Lists)
# gem 'blacklight_unapi', ">= 0.0.3"

#  ###  BLACKLIGHT (end)  ###

# A recent Kaminari update broke blacklight facet pagination.
# https://github.com/amatsuda/kaminari/commit/5e2e505cdd2ea2de20949d5cef261c247b3168b1
# This isn't fixed in Blacklight until 5.5.0,
# so pin kaminari to a pre-breakage release
gem 'kaminari', '0.15.0'

gem 'devise'
gem 'devise-encryptable'

# CAS is ready.  No more wind.
# ... but try to run them both during transition
# # pull from rubygems...
# # gem 'devise_wind'
# # Local copy relaxes rails version requirements (allows 4.x)
# # gem "devise_wind", :path => "/Users/marquis/src/devise_wind"
# # New branch to recover from when CUIT broke wind
gem "devise_wind", :git => 'git://github.com/cul/devise_wind.git', :branch => 'broke_wind'
# CAS is ready.
gem 'devise_cas_authenticatable'
# for debugging, use local version...
# gem 'devise_cas_authenticatable', path: '/Users/marquis/src/devise_cas_authenticatable'

# Not being used, turn it off.
# # Locally developed library code to interface with ClickTale analytics
# gem 'clicktale', path: "lib/clicktale"

gem 'json'

# Called to produce status msgs. search result lists.
# This could be native to clio-spectrum, or put into Voyager-back-end
# gem 'voyager_oracle_api', ">= 1.1.1"

# Would be used for Patron services, if we were to use native Blacklight Patron services
# gem 'restful_voyage', :git => "git://github.com/cul/restful_voyage.git", :branch => "master"

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

# gem 'therubyracer', '0.10.2'
gem 'therubyracer'
gem 'httpclient'
gem 'nokogiri'

# HTML replacement language
gem 'haml'
gem 'haml-rails'

# CSS replacement language
gem 'sass'
# dup - also in the assets group, below
# gem 'sass-rails', '~>3.2.4'

gem 'unicode'
gem 'summon'
gem 'cancan'

# doesn't work in Rails 4 ??
# RecordMailer uses partials that do fragment caching... but somehow
# this just doesn't work in stock rails.
gem 'caching_mailer'

# Talks to Voyager API directly, return XML-format for Spectrum use.
# But, this is now used from within the Voyager-Backend application
# (which is now named cul/clio_backend up at github), and so
# this is no longer needed here within clio-spectrum.
# gem 'voyager_api', '>=0.2.3'

gem 'exception_notification'
gem 'net-ldap'

# 3/15, comment out for now to simplify output,
#  we can turn it back on when we want it again.
# # application monitoring tool
# gem 'newrelic_rpm'

# "Rack middleware which cleans up invalid UTF8 characters"
# gem 'rack-utf8_sanitizer'
# Use github master branch, to pick up a few new patches.
# Maybe this will fix one of our outstanding issues:
#    application#catch_404s (ArgumentError) "invalid %-encoding"
# We also still have invalid %-encoding w/submitted form fields.
# This is an open issue at rack-utf8_sanitizer.
# gem 'rack-utf8_sanitizer', :github => 'whitequark/rack-utf8_sanitizer'
gem 'rack-utf8_sanitizer', :git => 'git://github.com/whitequark/rack-utf8_sanitizer'

# gives us jQuery and jQuery-ujs, but not jQuery UI
# (blacklight_range_limit brings this in anyway - no way to switch to CDN)
gem 'jquery-rails'

# # jQuery UI - JavaScript, CSS, Images
# gem 'jquery-ui-rails'

group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier'
  # gem 'bootstrap-sass', '3.2.0.2'
  gem 'bootstrap-sass'
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
  # gem 'guard-rails'

  # alternative webserver
  # gem 'hooves'
  # gem 'unicorn'

  #gem 'linecache19', '0.5.13'
  #gem 'ruby-debug-base19', '0.11.26'
  #gem 'ruby-debug19', :require => 'ruby-debug'

  # Deploy with Capistrano
  gem 'capistrano', '~>2'
  gem 'capistrano-ext'

  # don't show all those 'rendered...' lines in server logs
  gem 'quiet_assets'

  # fixes [morrison.cul.columbia.edu] sh: bundle: command not found
  gem 'rvm-capistrano'

  # browser-based live debugger and REPL
  # http://railscasts.com/episodes/402-better-errors-railspanel
  gem 'better_errors'
  gem 'binding_of_caller'
  # is this what's slowing us down so much?
  # gem 'meta_request'

  # port of ruby-debug that works on 1.9.2 and 1.9.3
  gem 'debugger'

  # We haven't used this for a while, turn it off for now.
  # # "A fist full of code metrics"
  # gem 'metric_fu'

  # Profiling experiments
  # https://www.coffeepowered.net/2013/08/02/ruby-prof-for-rails/
  # gem 'request_profiler', :git => "git://github.com/justinweiss/request_profiler.git"

end

group :test, :development do


  gem 'thin'
  # gem 'unicorn'


  # why in test and dev both instead of just test?  
  # because is says to: https://github.com/rspec/rspec-rails
  # gem 'rspec-rails', '>=2.14'
  gem 'rspec-rails'
end

group :test do
  gem 'factory_girl_rails'
  # # gem 'spork', '~>1.0.0.rc2'
  # gem 'spork'

  # gem 'guard'
  # gem 'guard-rspec'
  # gem 'guard-spork'

  # Copy Stanford's approach to Solr relevancy testing
  gem 'rspec-solr'

  # pin to old version, or go with newest?
  gem 'capybara'
  # gem 'capybara', '2.0.3'

  # Which Capybara driver for JS support?
  # gem 'capybara-webkit', '1.1.0'
  # unpin - seems to still work
  gem 'capybara-webkit'

  # dependent on localhost's browser configs
  gem 'selenium-webdriver', '2.45.0'

  gem 'launchy'
  gem 'database_cleaner'
  # # Mac OS X 10.8 (Mountain Lion) Notifications replace growl
  # # http://protips.maxmasnick.com/mountain-lion-notifications-with-guard
  # # gem "growl"
  # gem 'terminal-notifier-guard'


  gem 'rb-fsevent'
  # GNTP is Growl's protocol - turn off, since no more Growl
  # gem 'ruby_gntp'
  gem 'ruby-prof'


  # code coverage
  gem 'simplecov'

  # CI servers want XML output from rspecs
  # gem 'ci_reporter'
  
end
