# http://stackoverflow.com/questions/15307742
# http://stackoverflow.com/questions/14881011
# http://devblog.avdi.org/2012/08/31/configuring-database_cleaner
# rspec with Capybara with :js => true runs multiple threads against SQLlite,
# needs to run non-transactionally to avoid
# "SQLite3::BusyException: database is locked"

RSpec.configure do |config|

  # No, let whatever got in there remain in place.
  # config.before(:suite) do
  #   DatabaseCleaner.clean_with(:truncation)
  # end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation,
                               { except: %w(locations libraries library_hours options) }
  end

  config.before(:each, selenium: true) do
    DatabaseCleaner.strategy = :truncation,
    { except: %w(locations libraries library_hours options) }
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

end
