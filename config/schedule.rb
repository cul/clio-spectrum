# Use this file to easily define all of your cron jobs.

# Load rails environment
require File.expand_path('../config/environment', __dir__)

# Set environment to current environment.
set :environment, Rails.env

# Give our jobs nice subject lines
set :subject, 'cron output'
set :recipient, 'clio-dev@library.columbia.edu'
set :job_template, "/usr/local/bin/mailifoutput -s ':subject (:environment)' :recipient  /bin/bash -c ':job'"


# TODO
# We need to do some time offsets, so that our three server environments
# don't fire off the same job at the same moment


# Our batch processing environments
if %w(clio_app_dev clio_app_test clio_prod).include?(@environment)

  # == AUTHORITIES ==
  # Run all daily ingest tasks, together within one rake task
  every :day, at: '1am' do
    rake 'authorities:daily', subject: 'authorities:daily'
  end

  # == BIBLIOGRAPHIC ==
  # Run all daily ingest tasks, together within one rake task
  every :day, at: '2am' do
    rake 'bibliographic:daily', subject: 'bibliographic:daily'
  end

  # == DATABASE MAINTENANCE ==
  every :day, at: '3:10am' do
    rake 'blacklight:delete_old_searches[1]', subject: 'blacklight:delete_old_searches'
  end
  every :day, at: '3:20am' do
    rake 'sessions:cleanup[1]', subject: 'sessions:cleanup'
  end
  every :day, at: '3:30am' do
    rake 'hours:update_all', subject: 'hours:update_all'
  end

  # == RECAP ==
  every :day, at: '5am' do
    rake 'recap:delete_new[2]', subject: 'recap:delete_new'
  end
  every :day, at: '6am' do
    rake 'recap:ingest_new[2]', subject: 'recap:ingest_new'
  end

  # == LAW ==
  # Weekly full load of all Law records
  every :sunday, at: '8am' do
    rake 'bibliographic:extract:process EXTRACT=law', subject: 'law load'
  end


end

# Anything for PROD only?
if ['clio_prod'].include?(@environment)

  # == RECAP ==
  # Only download ReCAP extract files from SCSB once.
  # Then each environment can index from this local location individually.
  every :day, at: '11:30pm' do
    rake 'recap:download', subject: 'recap download'
  end

end
