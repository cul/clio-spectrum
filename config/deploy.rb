set :default_stage, "na_dev"
set :stages, %w(na_dev na_test na_prod spectrum_dev spectrum_test)

require 'capistrano/ext/multistage'
require 'bundler/capistrano'


default_run_options[:pty] = true

set :application, "new_arrivals"
set :scm, :git
set :git_enable_submodules, 1
set :deploy_via, :remote_cache
set :repository,  "git@github.com:cul/clio-spectrum.git"
set :use_sudo, false

namespace :deploy do
  desc "Restart Application"
  task :restart, :roles => :app do
    run "mkdir -p #{current_path}/tmp/cookies"
    run "touch #{current_path}/tmp/restart.txt"
  end

  task :symlink_shared do
    run "ln -nfs #{deploy_to}shared/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{deploy_to}shared/app_config.yml #{release_path}/config/app_config.yml"
    run "mkdir -p #{deploy_to}shared/extracts"
    run "ln -nfs #{deploy_to}shared/extracts #{release_path}/tmp/extracts"
  end

  desc "Compile asets"
  task :assets do
    run "cd #{release_path}; RAILS_ENV=#{rails_env} bundle exec rake assets:clean assets:precompile"
  end

end



after 'deploy:update_code', 'deploy:symlink_shared'
before "deploy:symlink", "deploy:assets"
