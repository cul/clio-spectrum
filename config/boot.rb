ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

# require 'rubygems'
#
# # Set up gems listed in the Gemfile.
# ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
#
# require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
#
#
# # http://stackoverflow.com/questions/28668436
# # Because, without this we can't use the /etc/hosts trick
# # to connect to 127.0.0.1 as "cliobeta.columbia.edu"
# require 'rails/commands/server'
#
# module Rails
#   class Server
#     alias :default_options_alias :default_options
#     def default_options
#       default_options_alias.merge!(Host: '0.0.0.0')
#     end
#   end
# end
