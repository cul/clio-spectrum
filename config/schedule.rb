# Use this file to easily define all of your cron jobs.

# Load rails environment
require File.expand_path('../config/environment', __dir__)

# Set environment to current environment.
set :environment, Rails.env

# We're going to assume that the cron environment has PATH setup correctly
# - including /usr/local/bin, for mailifoutput
# - including the correct RVM wrapper directory, for 'bundle exec'

# Give our jobs nice subject lines
set :subject, 'cron output'
set :recipient, 'clio-dev@library.columbia.edu'
set :job_template, "mailifoutput -s ':subject (:environment)' :recipient  /bin/bash -c ':job'"

# default job_type definition for "rake"
# job_type :rake,    "cd :path && :environment_variable=:environment bundle exec rake :task --silent :output"




# Our batch processing environments
if %w(clio_batch_dev clio_batch_test clio_batch_prod).include?(@environment)

  if @environment.eql?('clio_batch_dev')
    set :path, '/opt/clio/batch_dev/current'
    offset = 'two hours after '
  end
  if @environment.eql?('clio_batch_test')
    set :path, '/opt/clio/batch_test/current'
    offset = 'one hour after '
  end
  if @environment.eql?('clio_batch_prod')
    set :path, '/opt/clio/batch_prod/current'
    offset = ''
  end


  # == BIBLIOGRAPHIC ==
  # Run all daily ingest tasks, together within one rake task.
  # The daily clio-extract needs to complete before this.
  # That begins at 10pm and usually completes by midnight.
  every :day, at: offset + '1am' do
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
  every :day, at: offset + '7am' do
    rake 'recap:delete_new[2]', subject: 'recap:delete_new'
  end
  every :day, at: offset + '8am' do
    rake 'recap:ingest_new[2]', subject: 'recap:ingest_new'
  end

  # == AUTHORITIES ==
  # Run all daily ingest tasks, together within one rake task
  every :day, at: offset + '9am' do
    rake 'authorities:daily', subject: 'authorities:daily'
  end

  # == LAW ==
  # Weekly full load of all Law records
  every :sunday, at: offset + '10am' do
    rake 'bibliographic:extract:process EXTRACT=law', subject: 'law load'
  end

end

# Anything for PROD-BATCH only?
if ['clio_batch_prod'].include?(@environment)

  # == RECAP ==
  # Only download ReCAP extract files from SCSB once.
  # Then each environment can index from this local location individually.
  every :day, at: '11:30pm' do
    rake 'recap:download', subject: 'recap download'
  end

  # NEXT-1822 - SimplyE ETL workflow replaced with API lookup
  # # == SIMPLYE ==
  # # Daily reload of SimplyE links
  # every :day, at: '2am' do
  #   rake 'simplye:process', subject: 'simplye:process'
  # end

end
