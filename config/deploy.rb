set :default_stage, "taft_dev"
set :stages, %w(taft_dev taft_test)

require 'capistrano/ext/multistage'
default_run_options[:pty] = true

set :scm, :git
set :repository,  "git@github.com:tastyhat/cul-blacklight-new_books.git"
set :application, "newbooks"
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
   
  end

end


after 'deploy:update_code', 'deploy:symlink_shared'
