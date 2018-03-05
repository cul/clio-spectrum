Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.seconds.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker
end






# Clio::Application.configure do
#   # Settings specified here will take precedence over those in config/application.rb
# 
#   # less logging - turn on/off as needed for local development
#   config.log_level = :debug
#   # config.log_level = :warn
# 
#   # In the development environment your application's code is reloaded on
#   # every request.  This slows down response time but is perfect for development
#   # since you don't have to restart the webserver when you make code changes.
#   config.cache_classes = false
# 
#   # deprecated in rails 4
#   # # Log error messages when you accidentally call methods on nil.
#   # config.whiny_nils = true
# 
#   # Show full error reports and disable caching
#   config.consider_all_requests_local       = true
# 
#   # rails 4
#   config.eager_load = false
# 
#   # ***************
#   # *** CACHING ***
#   # ***************
#   # Turn development caching on to test Caching
#   config.action_controller.perform_caching = false
#   # config.action_controller.perform_caching = true
# 
#   # Cache store details - disk or memory?  How big?  (50MB?)
#   # config.cache_store = :memory_store, { size: 50_000_000 }
#   # Or... use redis?
#   # config.cache_store = :redis_store, APP_CONFIG['redis_url']
#   # Oops - can't use APP_CONFIG within environment files
#   # Cheat - redundantly read app_config right here...
#   ENV_CONFIG = YAML.load_file(File.expand_path('../../app_config.yml', __FILE__))[Rails.env]
#   if ENV_CONFIG && ENV_CONFIG['redis_url'].present?
#     config.cache_store = :redis_store, ENV_CONFIG['redis_url']
#   end
# 
#   # config.assets.compress = false
#   config.assets.debug = true
#   config.assets.digest = false
#   config.assets.logger = nil
# 
#   # Don't care if the mailer can't send
#   config.action_mailer.delivery_method = :test
#   config.action_mailer.raise_delivery_errors = false
# 
#   # Print deprecation notices to the Rails logger
#   config.active_support.deprecation = :log
# 
#   # # Gone in rails 4
#   # config.active_record.auto_explain_threshold_in_seconds = 0.5
# 
#   # Only use best-standards-support built into browsers
#   config.action_dispatch.best_standards_support = :builtin
# 
#   # in development, rails should hand off emails to localhost's sendmail
#   config.action_mailer.delivery_method = :sendmail
#   config.action_mailer.perform_deliveries = true
#   config.action_mailer.raise_delivery_errors = true
# 
#   # http://asciicasts.com/episodes/151-rack-middleware
#   # This gives us a total load time, as a comment before the opening <htm> tag.
#   # Debugging in development only, and if it causes problems just comment out.
#   # It DOES cause problems.  As mentioned in the RailsCasts discussions on this
#   # episode, the headers indicate the byte-length of the payload, and if we 
#   # insert a dozen bytes in the front of the payload, then the final dozen
#   # bytes at the end will not make it through.  
#   # config.middleware.use 'ResponseTimer'
# 
#   # Experiments with in-depth profiling
#   # https://github.com/justinweiss/request_profiler
#   # config.middleware.use "Rack::RequestProfiler"
#   # https://www.coffeepowered.net/2013/08/02/ruby-prof-for-rails/
#   # config.middleware.insert 0, "Rack::RequestProfiler", :printer => ::RubyProf::CallTreePrinter
# 
# end
