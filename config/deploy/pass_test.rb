set :rails_env, "pass_test"
set :application, "new_arrivals_test"
set :domain,      "rhys.cul.columbia.edu"
set :deploy_to,   "/opt/passenger/#{application}/"
set :user, "deployer"
set :branch, @variables[:branch] || "pass_test"
set :scm_passphrase, "Current user can full owner domains."

role :app, domain
role :web, domain
role :db,  domain, :primary => true



