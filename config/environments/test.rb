Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  # config.eager_load = false
  config.eager_load = true

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.seconds.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false
  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  #   # Asset approach for test runs
  #   config.assets.compile = true
  #   config.assets.compress = false
  #   config.assets.debug = false
  config.assets.digest = false

end



# Clio::Application.configure do
#   # Settings specified here will take precedence over those in config/application.rb
# 
#   # The test environment is used exclusively to run your application's
#   # test suite.  You never need to work with it otherwise.  Remember that
#   # your test database is "scratch space" for the test suite and is wiped
#   # and recreated between test runs.  Don't rely on the data there!
# 
#   config.cache_classes = !(ENV['DRB'] == 'true')
# 
#   # # deprecated in rails 4
#   # # Log error messages when you accidentally call methods on nil.
#   # config.whiny_nils = true
# 
#   # Show full error reports and disable caching
#   config.consider_all_requests_local       = true
# 
#   # Caching?  No, not during rspec testing.
#   # If remote datasource is down, or display logic is updated,
#   # cached fragment will have a broken or stale version of the page.
#   config.action_controller.perform_caching = false
#   # config.action_controller.perform_caching = true
# 
#   # Asset approach for test runs
#   config.assets.compile = true
#   config.assets.compress = false
#   config.assets.debug = false
#   config.assets.digest = false
# 
#   # Raise exceptions instead of rendering exception templates
#   config.action_dispatch.show_exceptions = false
# 
#   # Disable request forgery protection in test environment
#   config.action_controller.allow_forgery_protection    = false
# 
#   # Tell Action Mailer not to deliver emails to the real world.
#   # The :test delivery method accumulates sent emails in the
#   # ActionMailer::Base.deliveries array.
#   config.action_mailer.delivery_method = :test
# 
#   # Use SQL instead of Active Record's schema dumper when creating the test database.
#   # This is necessary if your schema can't be completely dumped by the schema dumper,
#   # like if you have constraints or database-specific column types
#   # config.active_record.schema_format = :sql
# 
#   # Print deprecation notices to the stderr
#   config.active_support.deprecation = :stderr
# 
#   # rails 4
#   config.eager_load = false
# 
#   # getting errors.  
#   # 2015-09-22 11:23:24 [ERROR] Spectrum::SearchEngines::Solr#initialize [Spectrum][Solr] error: Circular dependency detected while autoloading constant Spectrum::SolrRepository
#   # Will this help?
#   #   https://robots.thoughtbot.com/how-to-fix-circular-dependency-errors
#   # Yes!  Errors gone!
#   # Supposed to be fixed in Rails 4.2, try removing this config line when 
#   # we upgrade.
#   # config.allow_concurrency = false
# 
# end
