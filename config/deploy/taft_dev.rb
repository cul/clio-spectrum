set :rails_env, "taft_dev"
set :application, "newbooks_dev"
set :domain,      "taft.cul.columbia.edu"
set :deploy_to,   "/opt/passenger/#{application}/"
set :user, "deployer"
set :branch, @variables[:branch] || "taft_dev"
set :scm_passphrase, "Current user can full owner domains."

role :app, domain
role :web, domain
role :db,  domain, :primary => true



