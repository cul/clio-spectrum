# Use this file to easily define all of your cron jobs.

# Load rails environment
require File.expand_path('../config/environment', __dir__)

# Set environment to current environment.
set :environment, Rails.env

# Give our jobs nice subject lines
set :subject, 'cron output'
set :recipient, 'clio-dev@library.columbia.edu'
set :job_template, "/usr/local/bin/mailifoutput -s ':subject (:environment)' :recipient ':job'"

# CLIO DEV
if @environment == 'clio_dev'
  every :day, at: '1am' do
    rake 'bibliographic:extract:process EXTRACT=incremental', subject: 'daily incremental'
  end
end


# # Run on every host - dev, test, prod
# every :day, at: '1am' do
#   rake 'metadata:process', subject: 'GeoData metadata:process output'
# end



# Examples of per-environment cron commands
# 
# if @environment == "geoblacklight_dev"
#     every :weekday, :at => '10pm' do
#         # rake "foo:bar"
#     end
# end
