
# shouldn't be necessary?
ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'capybara/rspec'

require 'holdings/collection'
require 'holdings/item'
require 'holdings/record'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec
  config.include(MailerMacros)
  config.before(:each) { reset_email }

  config.around(:each, :selenium) do |example|
    Capybara.current_driver = :selenium
    example.run
  end

  # Specify an alternative JS driver if we want to avoid selinium
  Capybara.javascript_driver = :webkit
  # Capybara.javascript_driver = :webkit_debug

  # How long does Capybara wait for AJAX before erroring?
  # The 2-second default is fine for on-campus testing, but
  # for telecommuters more time is needed
  # https://github.com/jnicklas/capybara#asynchronous-javascript-ajax-and-friends
  Capybara.default_max_wait_time = 10

  config.filter_run focus: true
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

  # 3/15 - seems to be needed for rails 4?
  # Include path helpers
  config.include Rails.application.routes.url_helpers
  # and this???
  # http://stackoverflow.com/questions/15148585/undefined-method-visit
  config.include Capybara::DSL

  # Allow developers to turn off selenium-based testing
  # with a local setting in their app_config.yml
  config.filter_run_excluding :selenium if
      APP_CONFIG['skip_selenium_tests']

  # Some specs are awkward to run on Travis.
  # Flag them with a :skip_travis
  config.filter_run_excluding :skip_travis if ENV['TRAVIS']

  # This says to assume things in spec/controllers are controller
  # specs, etc.  No longer automatic with new rspec?
  config.infer_spec_type_from_file_location!

  config.example_status_persistence_file_path = 'spec/examples.txt'
end

Capybara::Webkit.configure do |config|
  config.block_unknown_urls

  # We test response data from these sites
  config.allow_url('hathitrust.org')
  config.allow_url('books.google.com')

end
