source 'https://rubygems.org'

gem 'rails', '~> 4.2'

gem 'activerecord-session_store'

#  ###  BLACKLIGHT (begin)  ###

gem 'blacklight', '~>5.0'

gem 'blacklight-marc'

# # gem 'blacklight_range_limit', :git => 'git://github.com/projectblacklight/blacklight_range_limit.git', :tag => 'v2.1.0'
# 
# # gem 'blacklight_range_limit', :git => 'git://github.com/projectblacklight/blacklight_range_limit.git', :branch => 'master'
# gem 'blacklight_range_limit', :git => 'git://github.com/projectblacklight/blacklight_range_limit.git', :branch => 'blacklight-master'

gem 'blacklight_range_limit'

# The next blacklight_range_limit requires blacklight 5.15
# gem 'blacklight_range_limit', :github => 'projectblacklight/blacklight_range_limit', :tag => 'v5.2.0'


#  ###  BLACKLIGHT (end)  ###


# Only used for Google Maps location pages
gem 'rest-client'
gem 'gmaps4rails'

# pagination
gem 'kaminari'

gem 'devise'
gem 'devise-encryptable'

# CAS is ready.  No more wind.
# ... but try to run them both during transition
# # pull from rubygems...
# # gem 'devise_wind'
# # Local copy relaxes rails version requirements (allows 4.x)
# # gem "devise_wind", :path => "/Users/marquis/src/devise_wind"
# # New branch to recover from when CUIT broke wind
# gem "devise_wind", :git => 'git://github.com/cul/devise_wind.git', :branch => 'broke_wind'
# CAS is ready.
gem 'devise_cas_authenticatable'
# for debugging, use local version...
# gem 'devise_cas_authenticatable', path: '/Users/marquis/src/devise_cas_authenticatable'

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
# 3/15, moved to local library code
# gem 'has_options'

# I think this had been added to allow JavaScript specs. But with
#  our current capybara-webkit driver, this is no longer needed.
# Oops.  This is needed for assets pre-compilation on bruckner.
# assets precompilation works on clio-dev and clio-test, but
# not on clio-prod.  Maybe difference in local gems?
# OK, node now installed on bruckner, try deploy w/out this.
# @#$%, something happened to the deploy environments, and 
# /usr/local/bin dropped from the path - no node, broken CLIO.
# Just put this back in there, it's a bit more code, but it
# defends us against unstable server environments.
gem 'therubyracer'

gem 'httpclient'

gem 'nokogiri'

# HTML replacement language
gem 'haml'

# 3/15 - I never looked at this before, but now that it's causing
# version dependency problems, maybe try removing it
# "Haml-rails provides Haml generators for Rails 4"
# gem 'haml-rails'

# CSS replacement language
gem 'sass'

# use Redis for our cache store
gem 'redis-rails'

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
# 3/15
# gem 'caching_mailer'
# Here's one that's supposed to work for Rails 4.
# gem 'mailer_fragment_caching'
# but it doesn't.

gem 'exception_notification'
gem 'net-ldap'

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

# # jQuery UI - JavaScript, CSS, Images
# gem 'jquery-ui-rails'

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


# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development do

  # # Deploy with Capistrano
  # gem 'capistrano', '~>2'
  # gem 'capistrano-ext'
  # # fixes [morrison.cul.columbia.edu] sh: bundle: command not found
  # gem 'rvm-capistrano'

  # Upgrade to Capistrano 3.x
  # http://capistranorb.com/documentation/upgrading/
  gem 'capistrano', '~> 3.0', require: false
  # Rails and Bundler integrations were moved out from Capistrano 3
  gem 'capistrano-rails',   '~> 1.1', require: false
  gem 'capistrano-bundler', '~> 1.1', require: false
  # "idiomatic support for your preferred ruby version manager"
  gem 'capistrano-rvm',   '~> 0.1', require: false
  # The `deploy:restart` hook for passenger applications is now in a separate gem
  # Just add it to your Gemfile and require it in your Capfile.
  gem 'capistrano-passenger',   '~> 0.1', require: false


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

  # Works with the Rails Panel plugin for Chrome
  # gem 'meta_request'

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
  # rspec mocks are externalized in an another gem rspec-activemodel-mocks
  # http://stackoverflow.com/a/24060582/1343906
  gem 'rspec-activemodel-mocks'
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
  
  # Travis needs this.
  #  http://docs.travis-ci.com/user/languages/ruby/
  gem 'rake'

  # Travis can use this to send coverage data over to Code Climate
  # http://docs.travis-ci.com/user/code-climate/
  # https://codeclimate.com/repos/556c823fe30ba007ad0069ee/coverage_setup
  gem "codeclimate-test-reporter", require: nil

  # Coveralls for Code Coverage
  # https://coveralls.zendesk.com/hc/en-us/articles/201769485-Ruby-Rails
  gem 'coveralls', require: false
  
  # Record API responses, use saved responses for tests
  gem 'vcr'
  gem 'webmock'
end

