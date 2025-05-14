Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # during FOLIO development I need better visibility
  config.consider_all_requests_local       = true

  # Attempt to read encrypted secrets from `config/secrets.yml.enc`.
  # Requires an encryption key in `ENV["RAILS_MASTER_KEY"]` or
  # `config/secrets.yml.key`.
  config.read_encrypted_secrets = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = Uglifier.new(harmony: true)
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Mount Action Cable outside main process or domain
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :debug

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id]

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment)
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "clio_#{Rails.env}"
  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV['RAILS_LOG_TO_STDOUT'].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # don't try to do file_store on an NFS mount
  config.cache_store = :memory_store, { size: 32.megabytes }
end

# Clio::Application.configure do
#   # Settings specified here will take precedence over those in config/application.rb
#
#   config.cache_classes = true
#
#   # # deprecated in rails 4
#   # # Log error messages when you accidentally call methods on nil.
#   # config.whiny_nils = true
#
#   # if we consider them "local" we spew errors to the browser
#   config.consider_all_requests_local       = false
#
#   # Do we want caching (page-, action-, fragment-) in this environment?
#   config.action_controller.perform_caching = true
#
#   # Cache store details - disk or memory?  How big?  (50MB?)
#   # config.cache_store = :memory_store, { size: 50_000_000 }
#   # Or... use redis?
#   # config.cache_store = :redis_store, APP_CONFIG['redis_url']
#   # Oops - can't use APP_CONFIG within environment files
#   # Cheat - redundantly read app_config right here...
#   ENV_CONFIG = YAML.load_file(File.expand_path('../../app_config.yml', __FILE__))[Rails.env]
#   if ENV_CONFIG && ENV_CONFIG && ENV_CONFIG['redis_url'].present?
#     config.cache_store = :redis_store, ENV_CONFIG['redis_url']
#   else
#     config.cache_store = :memory_store, { size: 50_000_000 }
#   end
#
#   # Don't care if the mailer can't send
#   config.action_mailer.raise_delivery_errors = true
#   config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'
#
#   config.action_mailer.delivery_method = :smtp
#   config.action_mailer.smtp_settings = {
#     address: 'smtp.library.columbia.edu',
#     domain: 'library.columbia.edu',
#     port: '25'
#   }
#   # Print deprecation notices to the Rails logger
#   config.active_support.deprecation = :log
#
#   # Don't compress, to help with debugging...
#   # config.assets.compress = true
#   # config.assets.compress = false
#   config.assets.compile = false
#   # # CLIO DEV is another environment where we'll want to debug asset issues
#   # config.assets.debug = true
#   config.assets.digest = true
#   # config.assets.digest = false
#   # We want to see this in CLIO Dev
#   # config.assets.logger = nil
#
#   # turn off logging of view/parital rendering?
#   # - no, we want to see this in CLIO Dev
#   # config.action_view.logger = nil
#
#   # Only use best-standards-support built into browsers
#   config.action_dispatch.best_standards_support = :builtin
#
#   # rails 4
#   config.eager_load = true
# end
#
# # Exception Notifier - Upgrading to 4.x version
# #   https://github.com/smartinez87/exception_notification/blob/master/README.md
# # Clio::Application.config.middleware.use ExceptionNotifier,
# #    :email_prefix => "[Clio Dev] ",
# #    :sender_address => %{"notifier" <spectrum-tech@libraries.cul.columbia.edu>},
# #    :exception_recipients => %w{spectrum-tech@libraries.cul.columbia.edu},
# #    :ignore_crawlers => %w{Googlebot bingbot}
#
# Clio::Application.config.middleware.use ExceptionNotification::Rack,
#   ignore_exceptions: ['Errno::EHOSTUNREACH'] + ExceptionNotifier.ignored_exceptions,
#   ignore_crawlers: %w(Googlebot bingbot archive.org_bot),
#   email: {
#     email_prefix: '[Clio Dev] ',
#     sender_address: %("notifier" <spectrum-tech@libraries.cul.columbia.edu>),
#     exception_recipients: %w(spectrum-tech@libraries.cul.columbia.edu)
#   }
