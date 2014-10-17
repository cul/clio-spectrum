set :rails_env, 'clio_dev'
set :application, 'clio_dev'
set :domain,      'morrison.cul.columbia.edu'
set :deploy_to,   "/opt/passenger/litosys/#{application}/"
set :user, 'litoserv'
set :scm_passphrase, 'Current user can full owner domains.'

role :app, domain
role :web, domain
role :db,  domain, primary: true
