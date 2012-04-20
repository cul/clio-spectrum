source 'http://rubygems.org'
gem 'rails', '3.2.2'

gem 'mysql2'
gem 'sqlite3'

# Use unicorn as the web server
# gem 'unicorn'


# gem 'blacklight'
gem 'blacklight'
gem 'blacklight_range_limit'
gem 'blacklight_highlight'
gem 'blacklight_google_analytics'
gem 'blacklight_unapi'
gem 'json'

# Deploy with Capistrano

gem 'has_options'
gem 'httpclient'
gem 'nokogiri'
gem 'haml'
gem 'haml-rails'
gem 'sass'
gem 'sass-rails', '~>3.2.4'
gem 'unicode'
gem 'summon'

gem 'voyager_api', '>=0.2.3'
gem 'rubytree', '=0.5.2'

gem 'exception_notification'


#
# gem 'blacklight_advanced_search',:git => 'https://github.com/projectblacklight/blacklight_advanced_search.git'

gem 'jquery-rails'

group :assets do
  gem 'sass-rails', '~>3.2.4'
  gem 'coffee-rails', '~>3.2.2'
  gem 'compass-rails', '~>1.0.0'
  gem 'uglifier', '>=1.0.3'
  gem 'compass-susy-plugin', '>=0.9.0'
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
gem "devise", '1.5.3'
gem 'therubyracer'
group :development do

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
  gem 'guard-cucumber'
  gem 'cucumber'
  gem 'cucumber-rails'
  gem 'rspec-rails'
  gem 'capybara'
  gem 'capybara-webkit'
  gem 'launchy'
  gem 'database_cleaner'
end
