source 'http://rubygems.org'
gem 'rails', '3.2.8'


gem 'sqlite3'

# Use unicorn as the web server
# gem 'unicorn'


#gem 'blacklight', :git => "git://github.com/projectblacklight/blacklight.git", :branch => "master"
 gem 'blacklight', "~> 4.0.0" 
gem 'blacklight_range_limit', "~> 2.0.0" 
gem 'blacklight_google_analytics'
gem 'blacklight_unapi', ">= 0.0.3" 
gem 'json'

#gem 'voyager_oracle_api', :path => "~/code/voyager_oracle_api"

gem 'voyager_oracle_api', ">= 1.1.1"
gem 'restful_voyage', :git => "git://github.com/cul/restful_voyage.git", :branch => "master"

group :clio_dev, :clio_test, :clio_prod do
  gem 'mysql2'
end


# Deploy with Capistrano
#gem 'newrelic_rpm'
gem 'has_options'
gem 'httpclient'
gem 'nokogiri'
gem 'haml'
gem 'haml-rails'
gem 'sass'
gem 'sass-rails', '~>3.2.4'
gem 'unicode'
gem 'summon'
gem 'cancan'

#gem 'voyager_api', '>=0.2.3'
gem 'rubytree', '=0.5.2'

gem 'exception_notification'
gem 'net-ldap'

gem 'devise'
gem 'devise-encryptable'
gem 'devise_wind'
#
# gem 'blacklight_advanced_search',:git => 'https://github.com/projectblacklight/blacklight_advanced_search.git

gem 'compass-rails'

gem 'jquery-rails'

group :assets do
  gem 'sass-rails', '~>3.2.4'
  gem 'coffee-rails', '~>3.2.2'
  gem 'uglifier', '>=1.0.3'
  gem 'bootstrap-sass', '~>2.1'
  gem 'compass-rails'
end




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
gem 'therubyracer'
group :development do
  gem 'thin'
  #gem 'linecache19', '0.5.13'
  #gem 'ruby-debug-base19', '0.11.26'
  #gem 'ruby-debug19', :require => 'ruby-debug'
  gem 'capistrano'
  gem 'capistrano-ext'
end

group :test, :development do 
  gem 'rspec-rails'
  gem "growl"
  gem 'rb-fsevent'
  gem 'ruby_gntp'
  gem 'ruby-prof'
end

group :test do
  gem 'rb-readline'
  gem 'factory_girl_rails'
  gem 'spork', '~>1.0.0.rc2'
  gem 'guard'
  gem 'guard-rails'
  gem 'guard-rspec'
  gem 'guard-spork'
  gem 'rspec-rails'
  gem 'capybara'
  gem 'capybara-webkit'
  gem 'launchy'
  gem 'database_cleaner'
end
