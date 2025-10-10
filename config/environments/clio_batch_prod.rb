# frozen_string_literal: true

Rails.application.configure do
  # ---------------------------------------------------------------------------
  # Code loading and performance
  # ---------------------------------------------------------------------------

  # In Rails 5.2, eager loading is not on by default unless this is production.
  config.eager_load = true

  # Prevent code reloading between runs (recommended for batch/cron).
  config.cache_classes = true

  # ---------------------------------------------------------------------------
  # Logging
  # ---------------------------------------------------------------------------

  # Keep logs informative but not huge.
  config.log_level = :info

  # Rails 5.2 uses TaggedLogging by default; simple formatter is fine.
  # config.log_formatter = ::Logger::Formatter.new

  # Log to STDOUT if RAILS_LOG_TO_STDOUT is set (common for cron/docker).
  # if ENV["RAILS_LOG_TO_STDOUT"].present?
  #   logger           = ActiveSupport::Logger.new($stdout)
  #   logger.formatter = config.log_formatter
  #   config.logger    = ActiveSupport::TaggedLogging.new(logger)
  # end

  # ---------------------------------------------------------------------------
  # Error handling / diagnostics
  # ---------------------------------------------------------------------------

  # Don’t show detailed error pages; not relevant for non-web batch jobs.
  config.consider_all_requests_local = false

  # Log deprecations (Rails 5 syntax).
  config.active_support.deprecation = :log

  # ---------------------------------------------------------------------------
  # Framework features irrelevant to batch jobs
  # ---------------------------------------------------------------------------

  # Skip asset compilation and controller caching (no web layer here).
  config.assets.compile = false
  config.action_controller.perform_caching = false

  # Run Active Job tasks inline unless a queue adapter is configured elsewhere.
  # config.active_job.queue_adapter = :inline
end
