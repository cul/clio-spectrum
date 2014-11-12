set :default_stage, 'clio_dev'
# Temporarily define "morrison", for testing Unix Systems new nginx server
set :stages, %w(clio_dev clio_test clio_prod morrison)

require 'capistrano/ext/multistage'
require 'bundler/capistrano'
require 'date'

# http://rvm.io/deployment/capistrano
# https://github.com/wayneeseguin/rvm-capistrano
require 'rvm/capistrano'

default_run_options[:pty] = true

set :application, 'clio'

set :branch do
  default_tag = `git tag`.split("\n").last

  tag = Capistrano::CLI.ui.ask "Tag to deploy (make sure to push the tag first): [#{default_tag}] "
  tag = default_tag if tag.empty?
  tag
end

set :scm, :git
set :git_enable_submodules, 1
set :deploy_via, :remote_cache
set :repository,  'git@github.com:cul/clio-spectrum.git'
set :use_sudo, false

namespace :deploy do
  desc 'Add tag based on current version'
  task :auto_tag, roles: :app do
    current_version = IO.read('VERSION').to_s.strip + Date.today.strftime('-%y%m%d')
    tag = Capistrano::CLI.ui.ask "Tag to add: [#{current_version}] "
    tag = current_version if tag.empty?

    system("git tag -a #{tag} -m 'auto-tagged' && git push origin --tags")
  end

  desc 'Restart Application'
  task :restart, roles: :app do
    run "mkdir -p #{current_path}/tmp/cookies"
    run "touch #{current_path}/tmp/restart.txt"
  end

  task :symlink_shared do
    run "ln -nfs #{deploy_to}shared/robots.txt #{release_path}/public/robots.txt"
    run "ln -nfs #{deploy_to}shared/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{deploy_to}shared/app_config.yml #{release_path}/config/app_config.yml"
    run "ln -nfs #{deploy_to}shared/solr.yml #{release_path}/config/solr.yml"
    run "mkdir -p #{deploy_to}shared/extracts"
    run "ln -nfs #{deploy_to}shared/extracts #{release_path}/tmp/extracts"
  end

end

after 'deploy:update_code', 'deploy:symlink_shared'
