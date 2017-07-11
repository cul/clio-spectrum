# config valid only for current version of Capistrano
lock '3.8.2'

# set :application, 'my_app_name'
# set :repo_url, 'git@example.com:me/my_repo.git'
set :application, 'clio'
set :repo_url, 'git@github.com:cul/clio-spectrum.git'

# Default branch is :master
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')
set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/app_config.yml', 'config/blacklight.yml', 'public/robots.txt')

# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')
# 8/2015 - I don't think we need: 'tmp/sockets', 'vendor/bundle', 'public/system'
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/extracts')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }
# set :default_env, { path: "/opt/ruby/ruby-2.2.2/bin/ruby:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

# # Capistrano can't find passenger:
# #   ERROR: Phusion Passenger doesn't seem to be running
# # So tell it where we it's installed:
# #   https://github.com/capistrano/passenger/blob/master/README.md
# set :passenger_environment_variables, { :path => '$PATH:/opt/nginx/passenger/passenger-5.0.7/bin' }

# can't get "passenger-config restart-app" working
set :passenger_restart_with_touch, true

set :whenever_identifier, ->{ fetch(:stage) }

namespace :deploy do

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
