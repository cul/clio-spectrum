source 'http://rubygems.org'
gem 'rails', '3.1.0.rc5'

gem 'sprockets', '2.0.0.beta.13'
# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'sqlite3'

# Use unicorn as the web server
# gem 'unicorn'

#gem 'blacklight', :path => '~/code/blacklight'

gem 'blacklight', :git => 'git://github.com/cul/blacklight.git' , :branch => 'rails_31'
gem 'json'

# Deploy with Capistrano
gem 'capistrano'
gem 'capistrano-ext'

gem 'has_options'
gem 'httpclient'
gem 'nokogiri'
gem 'haml'
gem 'haml-rails'
gem 'unicode'
gem 'mysql'
gem 'summon'
gem 'voyager_api'
gem 'rubytree', '=0.5.2'
# gem 'blacklight_advanced_search',:git => 'https://github.com/projectblacklight/blacklight_advanced_search.git'

group :assets do
  gem 'sass-rails', "~> 3.1.0.rc"
  gem 'compass', :git => 'git://github.com/chriseppstein/compass.git', :branch => 'rails31'

end

gem 'jquery-rails'

gem 'unicorn'


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
gem "devise"

group :test do
  gem "database_cleaner"
  gem "capybara"
  gem "launchy"
  gem "rspec-rails"
  gem "rcov", ">= 0"
  gem "cucumber-rails"
  gem "guard-minitest"
  gem "mocha"
  gem "growl"
end
