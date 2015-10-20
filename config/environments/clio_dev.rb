
Clio::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  config.cache_classes = true

  # # deprecated in rails 4
  # # Log error messages when you accidentally call methods on nil.
  # config.whiny_nils = true

  # if we consider them "local" we spew errors to the browser
  config.consider_all_requests_local       = false

  # Do we want caching (page-, action-, fragment-) in this environment?
  config.action_controller.perform_caching = true

  # Cache store details - disk or memory?  How big?  (50MB?)
  config.cache_store = :memory_store, { size: 50_000_000 }

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true
  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: 'localhost',
    domain: 'bronte.cc.columbia.edu',
    port: '25'
  }
  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Don't compress, to help with debugging...
  # config.assets.compress = true
  config.assets.compress = false
  config.assets.compile = false
  # # CLIO DEV is another environment where we'll want to debug asset issues
  # config.assets.debug = true
  config.assets.digest = true
  # config.assets.digest = false
  # We want to see this in CLIO Dev
  # config.assets.logger = nil

  # turn off logging of view/parital rendering?
  # - no, we want to see this in CLIO Dev
  # config.action_view.logger = nil

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # rails 4
  config.eager_load = true
end

# Exception Notifier - Upgrading to 4.x version
#   https://github.com/smartinez87/exception_notification/blob/master/README.md
# Clio::Application.config.middleware.use ExceptionNotifier,
#    :email_prefix => "[Clio Dev] ",
#    :sender_address => %{"notifier" <spectrum-tech@libraries.cul.columbia.edu>},
#    :exception_recipients => %w{spectrum-tech@libraries.cul.columbia.edu},
#    :ignore_crawlers => %w{Googlebot bingbot}

Clio::Application.config.middleware.use ExceptionNotification::Rack,
                                        email: {
                                          email_prefix: '[Clio Dev] ',
                                          sender_address: %("notifier" <spectrum-tech@libraries.cul.columbia.edu>),
                                          exception_recipients: %w(spectrum-tech@libraries.cul.columbia.edu),
                                          ignore_crawlers: %w(Googlebot bingbot)
                                        }
