require 'simplecov'
SimpleCov.start do
  # don't do coverage of our testing code
  add_filter "/spec/"
  # don't do coverage of our rake tasks
  add_filter "/lib/tasks/"
end

require 'rubygems'
require 'spork'



Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'capybara/rspec'

  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  RSpec.configure do |config|
    config.mock_with :rspec
    config.include(MailerMacros)
    config.before(:each) { reset_email }

    # Specify an alternative JS driver if we want to avoid selinium
    Capybara.javascript_driver = :webkit
    # Capybara.javascript_driver = :webkit_debug

    # http://www.elabs.se/blog/60-introducing-capybara-2-1
    # But try to rewrite our specs so that we don't have to change
    # Capybara's default configuration settings.
    # Capybara.configure do |config|
      # config.match = :one
      # config.exact_options = true
      # config.ignore_hidden_elements = true
      # config.visible_text_only = true
    # end

    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.filter_run :focus => true
    config.run_all_when_everything_filtered = true

    # http://stackoverflow.com/questions/3333743
    # factory_girl + rspec doesn't seem to roll back changes after each example
    config.use_transactional_fixtures = true
    config.use_instantiated_fixtures  = false

    # http://stackoverflow.com/questions/15307742
    # http://stackoverflow.com/questions/14881011
    # http://devblog.avdi.org/2012/08/31/configuring-database_cleaner
    # rspec with Capybara with :js => true runs multiple threads against SQLlite,
    # needs to run non-transactionally to avoid 
    # "SQLite3::BusyException: database is locked"
    config.use_transactional_fixtures = false

  end

end

Spork.each_run do
  FactoryGirl.reload
  Clio::Application.reload_routes!
end

