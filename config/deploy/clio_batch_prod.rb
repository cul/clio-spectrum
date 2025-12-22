
set :bundle_without, %w(development test clio_dev clio_test clio_prod).join(' ')

set :bundle_env_variables, 'http_proxy' => 'http://lito-squid-prod1.cul.columbia.edu:3131',
                           'https_proxy' => 'http://lito-squid-prod1.cul.columbia.edu:3131'

# set :bundle_env_variables, 'http_proxy' => 'http://squid.cul.columbia.edu:3131'

server 'clio-service-prod2.cul.columbia.edu', user: 'clioserv', roles: %w(app db web)

# set :deploy_to, '/var/www/my_app_name'
# set :deploy_to, '/opt/passenger/clio_prod'
set :deploy_to, '/opt/clio/batch_prod'

# https://github.com/capistrano/rvm
# set :rvm_type, :user                     # Defaults to: :auto
# set :rvm_ruby_version, '2.0.0-p247'      # Defaults to: 'default'
# set :rvm_custom_path, '~/.myveryownrvm'  # only needed if not detected
set :rvm_ruby_version, 'clio_test'
