
NewBooks::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  config.cache_classes = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true
  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' 

config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  :address => "localhost",
  :domain => "bronte.cc.columbia.edu",
  :port => "25"
}
  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log
  config.assets.precompile += %w{flot/excanvas.min.js}
  config.assets.compress = true
  config.assets.compile = false
  config.assets.digest = true
  config.assets.debug = false

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin
end

NewBooks::Application.config.middleware.use ExceptionNotifier,
   :email_prefix => "[Spectrum Dev] ",
   :sender_address => %{"notifier" <spectrum@libraries.cul.columbia.edu>},
   :exception_recipients => %w{james.stuart+spectrum_dev@gmail.com},
   :ignore_crawlers => %w{Googlebot bingbot}
