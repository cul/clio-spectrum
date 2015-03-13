require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
if defined?(Bundler)
  Bundler.require *Rails.groups(assets: %w(development test))
end



RELEASE_STAMP = IO.read('VERSION').strip

# explicitly require, so that "config.middleware.use" works below during
# capistrano's assets:precompile step
require 'rack/attack'
require 'rack/utf8_sanitizer'

module Clio
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras #{config.root}/lib)
    config.autoload_paths += %W(#{config.root}/lib)


    # require File.expand_path('../../lib/monkey_patches', __FILE__)
    require 'monkey_patches'
    # require File.expand_path('../../lib/rsolr_notifications', __FILE__)
    require 'rsolr_notifications'
    require 'browse_support'

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = 'Eastern Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
     # config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '*.{rb,yml}').to_s]
     # config.i18n.default_locale = :en

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)
    config.assets.paths << "#{Rails.root}/app/assets/fonts"
    config.assets.precompile += %w(.svg .eot .woff .ttf)
    config.assets.precompile += %w( google_maps.js )

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = 'utf-8'
    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable the asset pipeline
    config.assets.enabled = true
    # Default SASS Configuration, check out https://github.com/rails/sass-rails for details

    config.assets.version = RELEASE_STAMP

    # see https://github.com/vidibus/vidibus-routing_error
    # This isn't great, since it doesn't tell us or them that anything
    # untoward has occurred!
    #
    # Catch 404s
    config.after_initialize do |app|
      app.routes.append { match '*catch_unknown_routes', to: 'application#catch_404s' }
    end

    # After seeing some: ActionDispatch::RemoteIp::IpSpoofAttackError
    # 1) this exception is not actually indicative of spoofing, just
    #    malformed requests, which in themselves are nothing to worry
    #    about, so disable the check.
    # http://stackoverflow.com/questions/7887932
    config.action_dispatch.ip_spoofing_check = false
    # 2) but we actually are vulnerable to spoofing, in that if the request
    #    simply has an X-Forwarded-for header, we trust that value instead
    #    of the source IP when we do our User.on_campus? check.
    #    we can always use remote_addr instead of remote_ip, or we can just
    #    turn off the middleware that populates remote_ip.
    # http://blog.gingerlime.com/2012/rails-ip-spoofing
    config.middleware.delete ActionDispatch::RemoteIp

    # https://github.com/kickstarter/rack-attack
    # "DSL for blocking & throttling abusive clients"
    config.middleware.use Rack::Attack

    # https://github.com/whitequark/rack-utf8_sanitizer
    # Rack::UTF8Sanitizer is a Rack middleware which cleans up
    # invalid UTF8 characters in request URI and headers.
    config.middleware.insert_before 'Rack::Runtime', Rack::UTF8Sanitizer

    # [deprecated] I18n.enforce_available_locales will default to true in the
    # future. If you really want to skip validation of your locale you can set
    # I18n.enforce_available_locales = false to avoid this message.
    # Good explanation here:
    #   http://stackoverflow.com/questions/20361428
    # config.i18n.enforce_available_locales = true
    # or if one of your gem compete for pre-loading, use
    I18n.config.enforce_available_locales = true

    # Rails 3.2 introduced the TaggedLogging class, which makes it easy for
    # developers to add custom tags to log messages.
    # One of the ways to use that is the config.log_tags setting in your
    # application.rb file. You can set this to an array of methods that
    # the request object responds to, and the results will be added as tags
    # to each request in logs.
    # (from http://api.rubyonrails.org/classes/ActionDispatch/Request.html
    # e.g., :original_url, :remote_ip, etc.)
    config.log_tags = [:remote_ip]
  end
end
