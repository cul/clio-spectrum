source 'https://rubygems.org'

gem 'rails', '~> 4.2'

gem 'activerecord-session_store'

#  ###  BLACKLIGHT (begin)  ###

gem 'blacklight', '~>6.10.0'
# gem 'blacklight', path: '/Users/marquis/src/blacklight'


gem 'blacklight-marc'

# local testing...
# gem 'blacklight_range_limit', path: '/Users/marquis/src/blacklight_range_limit'
gem 'blacklight_range_limit'



#  ###  BLACKLIGHT (end)  ###

# RSolr should be in your gemfile. Blacklight 6.0 will not load rsolr by default
# Pin at 1.x, 2.x gave me errors:  "solr" is not registered on Faraday::Adapter
gem 'rsolr', '~>1.0'

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
gem 'kaminari'

# Auth
gem 'devise'
gem 'devise-encryptable'

# Client-side JS timeouts
gem 'auto-session-timeout'

# CAS is ready.
# gem 'devise_cas_authenticatable', path: '/Users/marquis/src/devise_cas_authenticatable'
gem 'devise_cas_authenticatable'

gem 'json'

# Always include sqlite, deploy to all servers, so that we can use dummy databases
#  for simplified rails environments used in index rake cronjobs
gem 'sqlite3'

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
# gem 'summon', :git => 'git://github.com/cul/summon.git'
gem 'summon', git: 'https://github.com/cul/summon.git'
# Point to local copy during development...
# gem 'summon', :path => "/Users/marquis/src/summon"

# auth library
gem 'cancan'

gem 'exception_notification'

# Lookup Columbia user details
gem 'net-ldap'

# Fetch feed files from ReCAP
gem 'net-sftp'

# Talk to SCSB REST API
gem 'faraday'

# For, e.g., Google Custom Search API
gem 'google-api-client'

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

# jQuery UI
gem 'jquery-ui-rails'

# Assets processing
gem 'sass-rails'
gem 'coffee-rails'
gem 'uglifier'
gem 'bootstrap-sass'


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
gem "recaptcha", require: "recaptcha/rails"

# works with Traject to extract id numbers from MARC
gem 'library_stdnums'

# keep cron scheduling within application
gem 'whenever', require: false

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


  # Rails 4 - use config.action_view.logger instead
  # # don't log every rendered view/partial
  # gem 'quiet_assets'
  # But rails outputs two blank lines to log?
  # Ok, use this - but only for dev.
  gem 'quiet_assets'

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

  # why in test and dev both instead of just test?  
  # because is says to: https://github.com/rspec/rspec-rails
  gem 'rspec-rails'
  # rspec mocks are externalized in an another gem rspec-activemodel-mocks
  # http://stackoverflow.com/a/24060582/1343906
  gem 'rspec-activemodel-mocks'
end

group :test do
  gem 'factory_bot_rails'

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
  
  # Record API responses, use saved responses for tests
  gem 'vcr'
  gem 'webmock'
end

