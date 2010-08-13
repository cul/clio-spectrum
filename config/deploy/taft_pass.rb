set :rails_env, "taft_pass"
set :application, "newbooks_test"
set :domain,      "taft.cul.columbia.edu"
set :deploy_to,   "/opt/passenger/#{application}/"
set :user, "deployer"
set :branch, "taft_pass_test"
set :scm_passphrase, "Current user can full owner domains."

role :app, domain
role :web, domain
role :db,  domain, :primary => true


