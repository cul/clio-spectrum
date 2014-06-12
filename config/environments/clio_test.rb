
Clio::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # less logging
  config.log_level = :warn

  config.cache_classes = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

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
    domain: 'berlioz.cc.columbia.edu',
    port: '25'
  }

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  config.assets.compress = true
  config.assets.compile = false
  config.assets.digest = true
  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin
end

# Exception Notifier - Upgrading to 4.x version
#   https://github.com/smartinez87/exception_notification/blob/master/README.md
# Clio::Application.config.middleware.use ExceptionNotifier,
#    :email_prefix => "[Clio Test] ",
#    :sender_address => %{"notifier" <spectrum-tech@libraries.cul.columbia.edu>},
#    :exception_recipients => %w{spectrum-tech@libraries.cul.columbia.edu},
#    :ignore_crawlers => %w{Googlebot bingbot}

Clio::Application.config.middleware.use ExceptionNotification::Rack,
                                        email: {
                                          email_prefix: '[Clio Test] ',
                                          sender_address: %("notifier" <spectrum-tech@libraries.cul.columbia.edu>),
                                          exception_recipients: %w(spectrum-tech@libraries.cul.columbia.edu),
                                          ignore_crawlers: %w(Googlebot bingbot)
                                        }
