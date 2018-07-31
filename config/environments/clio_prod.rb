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
  # config.log_level = :debug
  config.log_level = :warn

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment)
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "clio_#{Rails.env}"
  config.action_mailer.perform_caching = false

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: 'smtp.library.columbia.edu',
    domain: 'library.columbia.edu',
    port: '25'
  }

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

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # turn off logging of view/parital rendering
  config.action_view.logger = nil

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # don't try to do file_store on an NFS mount
  config.cache_store = :memory_store, { size: 32.megabytes }

end

#   https://github.com/smartinez87/exception_notification
Rails.application.config.middleware.use ExceptionNotification::Rack,
  ignore_exceptions: ['Errno::EHOSTUNREACH', 'Mail::Field::ParseError', 'Mail::Field::IncompleteParseError', 'ActionController::BadRequest'] + ExceptionNotifier.ignored_exceptions,
  ignore_crawlers: %w(Googlebot bingbot archive.org_bot Blogtrottr Sogou Baidu Yandex),
  email: {
    email_prefix: '[Clio Prod] ',
    sender_address: %("notifier" <spectrum-tech@libraries.cul.columbia.edu>),
    exception_recipients: %w(spectrum-tech@libraries.cul.columbia.edu)
  }





# Clio::Application.configure do
#   # Settings specified here will take precedence over those in config/application.rb
# 
#   # less logging
#   config.log_level = :warn
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
#   # Cache store details - disk or memory?  How big?  (100MB?)
#   # (use number, because "100.megabytes" gives:  undefined method `megabytes'
#   #  see http://stackoverflow.com/questions/10200339)
#   config.cache_store = :memory_store, { size: 150_000_000 }
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
# 
#   # Print deprecation notices to the Rails logger
#   config.active_support.deprecation = :log
# 
#   # config.assets.compress = true
#   config.assets.compile = false
#   config.assets.digest = true
#   config.assets.logger = nil
# 
#   # Rails 4 - these are split out
#   # config.assets.css_compressor = :yui
#   # This is available from sass-rails gem
#   config.assets.css_compressor = :sass
#   config.assets.js_compressor = :uglifier
# 
#   # Only use best-standards-support built into browsers
#   config.action_dispatch.best_standards_support = :builtin
# 
#   # UnAPI has been removed.
#   # # BlacklightUnapi - quiet the extensive log entries:
#   # # DEPRECATION WARNING: Passing a template handler in the template
#   # # name is deprecated. You can simply remove the handler name or
#   # # pass render :handlers => [:builder] instead.
# 
#   # More noisy deprecations as we try to get BL + BL-Range-Limit
#   # upgraded enough...
#   ActiveSupport::Deprecation.silenced = true
# 
#   # rails 4
#   config.eager_load = true
# 
#   # turn off logging of view/parital rendering
#   config.action_view.logger = nil
# 
# end
# 
# #   https://github.com/smartinez87/exception_notification
# Clio::Application.config.middleware.use ExceptionNotification::Rack,
#   ignore_exceptions: ['Errno::EHOSTUNREACH', 'Mail::Field::ParseError', 'Mail::Field::IncompleteParseError', 'ActionController::BadRequest'] + ExceptionNotifier.ignored_exceptions,
#   ignore_crawlers: %w(Googlebot bingbot archive.org_bot Blogtrottr Sogou Baidu Yandex),
#   email: {
#     email_prefix: '[Clio Prod] ',
#     sender_address: %("notifier" <spectrum-tech@libraries.cul.columbia.edu>),
#     exception_recipients: %w(spectrum-tech@libraries.cul.columbia.edu)
#   }
