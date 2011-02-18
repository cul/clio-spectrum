set :rails_env, "rameau_prod"
set :application, "newbooks"
set :domain,      "rameau.cul.columbia.edu"
set :deploy_to,   "/opt/passenger/#{application}/"
set :user, "deployer"
set :branch, @variables[:branch] || "rameau_prod"
set :scm_passphrase, ""

role :app, domain
role :web, domain
role :db,  domain, :primary => true



