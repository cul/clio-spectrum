set :rails_env, "spectrum_dev"
set :application, "spectrum_dev"
set :domain,      "ldpdmac01.cul.columbia.edu"
set :deploy_to,   "/Users/jamesws3/passenger/#{application}/"
set :user, "deployer"
set :branch, @variables[:branch] || "spectrum_dev"
set :scm_passphrase, "Current user can full owner domains."

role :app, domain
role :web, domain
role :db,  domain, :primary => true



