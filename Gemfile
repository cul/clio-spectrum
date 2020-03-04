source 'https://rubygems.org'

gem 'rails', '~>5.0'

gem 'activerecord-session_store'

###  BLACKLIGHT (begin)  ###

gem 'blacklight', '~>6.10.0'
# gem 'blacklight', path: '/Users/marquis/src/blacklight'

gem 'blacklight-marc'

# local testing...
# gem 'blacklight_range_limit', path: '/Users/marquis/src/blacklight_range_limit'
gem 'blacklight_range_limit'

###  BLACKLIGHT (end)  ###

gem 'rsolr', '>= 1.0'
# gem 'rsolr', path: "/Users/marquis/src/rsolr"

# # Enable HTTP connection re-use within RSolr (Faraday)
# gem 'net-http-persistent'

# basic library to parse, create and manage MARC records
gem 'marc'

# MARC indexing in pure ruby
gem 'traject'
# # Try U.Mich's more detailed format classifier
# gem 'traject_umich_format'

# Only used for Google Maps location pages
gem 'rest-client'
gem 'gmaps4rails'

# pagination
gem 'kaminari', '~> 1.1.0'

# Authentication
gem 'devise', '~> 4.4.0'

# gem 'cul_omniauth'
# gem 'cul_omniauth', git: 'https://github.com/cul/cul_omniauth', branch: 'rails-5'
gem 'cul_omniauth', git: 'https://github.com/cul/cul_omniauth', branch: 'cas-5.3'

# Client-side JS timeouts
gem 'auto-session-timeout'

# Authorization
# gem 'cancan'
gem 'cancancan'

gem 'json'

# # Rails 5 requirement
# gem 'listen'

# Only in server environments - not localhost desktop
group :clio_dev, :clio_app_dev, :clio_test, :clio_app_test, :clio_prod do
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

# include JS runtime via bundler - server environment is unreliable
gem 'therubyracer'

gem 'httpclient'

gem 'nokogiri'

# HTML replacement language
gem 'haml'

# CSS replacement language
gem 'sass'

# nope, not ready for this
# # use Redis for our cache store
# gem 'redis-rails'

# fork local branch, to add network timeouts
# gem 'summon'
gem 'summon', git: 'https://github.com/cul/summon.git'
# Point to local copy during development...
# gem 'summon', :path => "/Users/marquis/src/summon"

# used to email exceptions to developers
gem 'exception_notification'

# Lookup Columbia user details
gem 'net-ldap'

# Fetch feed files from ReCAP
gem 'net-sftp'

# Talk to SCSB REST API
gem 'faraday'

# For, e.g., Google Custom Search API
gem 'google-api-client', '~> 0.36'

# 10/15 - not giving us insight beyond our debug_timestamp info
# # 3/15, comment out for now to simplify output,
# #  we can turn it back on when we want it again.
# # 9/15 - let's try to improve things a bit more
# # application monitoring tool
# gem 'newrelic_rpm'

# "Rack middleware which cleans up invalid UTF8 characters"
gem 'rack-utf8_sanitizer'

# gives us jQuery and jQuery-ujs, but not jQuery UI
# (blacklight_range_limit brings this in anyway - no way to switch to CDN)
gem 'jquery-rails'

# JQuery UI gives extra functionality, including draggable
gem 'jquery-ui-rails'

# Assets processing
# gem 'sass-rails'
# sass-rails 6.x uses sassc, which won't build on our CentOS 6 VMs
gem 'sass-rails', '~> 5.0'

gem 'coffee-rails'
gem 'uglifier'
# pin to 3.3, because 3.4 requires sassc, which won't build on our CenTOS 6 VMs
gem 'bootstrap-sass', '~> 3.3.0'

# Best Bets CRUD externalized
# # JSON APIs, for Best Bets, etc.
# gem 'jbuilder'

# Typeahead - for Best Bets, etc.
gem 'twitter-typeahead-rails'

# Cross-Origin Resource Sharing for Best Bets JSON
gem 'rack-cors', require: 'rack/cors'

# To build slugs for saved-list URLs
gem 'stringex'

# Allow recovery for deleted Saved Lists
gem 'paper_trail'

# I seriously have to do this?
gem 'rack'

# https://github.com/kickstarter/rack-attack
# A DSL for blocking & throttling abusive clients
gem 'rack-attack'

# Too much spam using our record emailer
gem 'recaptcha', require: 'recaptcha/rails'

# works with Traject to extract id numbers from MARC
gem 'library_stdnums'

# normalize call-numbers for sorting - soggy starr, xlsx download
gem 'lcsort'

# keep cron scheduling within application
gem 'whenever', require: false

# DataTables, for pretty log screens
gem 'jquery-datatables-rails'

# Browser Detection - used to exclude IE from ES6
gem 'browser'

# appears fixed, as of 2/19/2019
# # UNIX-5942 - work around spotty CUIT DNS
# gem 'resolv-hosts-dynamic'

# # Code profiling, and we want to do this on the servers
# # "This gem is MRI-specific. It does not support jruby"
# gem 'ruby-prof', platforms: :mri

# Streaming download of XLSX
gem 'xlsxtream'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development do
  # Upgrade to Capistrano 3.x
  # http://capistranorb.com/documentation/upgrading/
  gem 'capistrano', '~> 3.0', require: false
  # Rails and Bundler integrations were moved out from Capistrano 3
  gem 'capistrano-rails', require: false
  gem 'capistrano-bundler', require: false
  # "idiomatic support for your preferred ruby version manager"
  gem 'capistrano-rvm', require: false
  # The `deploy:restart` hook for passenger applications is now in a separate gem
  # Just add it to your Gemfile and require it in your Capfile.
  gem 'capistrano-passenger', require: false

  # browser-based live debugger and REPL
  # http://railscasts.com/episodes/402-better-errors-railspanel
  gem 'better_errors'
  gem 'binding_of_caller'

  # For code-level debugging in console
  gem 'byebug'

  # "A fist full of code metrics"
  # gem 'metric_fu'

  # Profiling experiments
  # https://www.coffeepowered.net/2013/08/02/ruby-prof-for-rails/
  # gem 'request_profiler', :git => "git://github.com/justinweiss/request_profiler.git"
end


group :test, :development do
  gem 'thin'

  # Only use this on localhost, mysql in server envirohnments
  gem 'sqlite3'
  # pin to 1.3.x - Rails 5.2.2 can't talk to sqlite3 1.4, when Rails moves up, remove constraint
  # gem "sqlite3", "~> 1.3.6"

  # Rspec for testing
  gem 'rspec-rails'
  gem 'rspec-activemodel-mocks'
end

group :test do
  gem 'factory_bot_rails'

  # Copy Stanford's approach to Solr relevancy testing
  gem 'rspec-solr'

  # pin to 2.x to avoid having to install/use puma
  gem 'capybara', '~>2.0'

  # Which Capybara driver for JS support?
  gem 'capybara-webkit'

  # Used for some Javascript testing that fails w/WebKit
  # but... we don't care much about those bits actually.
  # # dependent on localhost's browser configs
  # gem 'selenium-webdriver'

  # "A helper for launching cross-platform applications
  #  in a fire and forget manner."
  # Required to enable capybara's save_and_open_page() method
  gem 'launchy'

  # # reset database tables between test runs
  # gem 'database_cleaner'

  # Not doing anything with profiling just now, but when we get back to it,
  # reread:   https://www.coffeepowered.net/2013/08/02/ruby-prof-for-rails/
  # gem 'ruby-prof'

  # # code coverage
  # gem 'simplecov'

  # CI servers want XML output from rspecs
  # gem 'ci_reporter'

  # Travis needs this.
  #  http://docs.travis-ci.com/user/languages/ruby/
  gem 'rake'

  # # Travis can use this to send coverage data over to Code Climate
  # # http://docs.travis-ci.com/user/code-climate/
  # # https://codeclimate.com/repos/556c823fe30ba007ad0069ee/coverage_setup
  # gem "codeclimate-test-reporter", require: nil

  # # Coveralls for Code Coverage
  # # https://coveralls.zendesk.com/hc/en-us/articles/201769485-Ruby-Rails
  # gem 'coveralls', require: false

  # We stopped using this a while ago
  # # # Record API responses, use saved responses for tests
  # # gem 'vcr'
  # # gem 'webmock'

  # assert_template has been extracted to a gem. To continue using it,
  #         add `gem 'rails-controller-testing'` to your Gemfile.
  gem 'rails-controller-testing'
end
