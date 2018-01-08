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
if ['clio_app_dev', 'clio_app_test', 'clio_prod'].include?(@environment)


  # Ingest a partial slice of the 'full' extract.
  # Slice is based on day-of-the-month, so run this daily
  every :day, at: '1am' do
    rake 'bibliographic:extract:ingest_full_slice', subject: 'daily full slice'
  end

  # == DATABASE MAINTENANCE ==
  every :day, at: '2:10am' do
    rake 'blacklight:delete_old_searches[1]', subject: 'blacklight:delete_old_searches'
  end
  every :day, at: '2:20am' do
    rake 'sessions:cleanup[1]', subject: 'sessions:cleanup'
  end
  every :day, at: '2:30am' do
    rake 'hours:update_all', subject: 'hours:update_all'
  end

  # == BIBLIOGRAPHIC ==

  # Nightly incremental
  every :day, at: '3am' do
    rake 'bibliographic:extract:process EXTRACT=incremental', subject: 'daily incremental'
  end
  # Weekly cumulative, catch-up run in case we missed anything
  every :sunday, at: '4am' do
    rake 'bibliographic:extract:process EXTRACT=cumulative', subject: 'weekly cumulative'
  end

  # We've moved Authority variant lookups into the bibliographic ingest
  # #  ===  AUTHORITIES  ===
  # 
  # #  Add authority variants after each daily load 
  # every :day, at: '2am' do
  #   rake 'authorities:add_to_bib:by_extract[incremental]', subject: 'daily authorities'
  # end
  # # Weekly authority catch-up against cumulative
  # every :sunday, at: '6am' do
  #   rake 'authorities:add_to_bib:by_extract[cumulative]', subject: 'weekly authorities'
  # end

  # == RECAP ==
  #  Add authority variants after each daily load 
  every :day, at: '5am' do
    rake 'recap:delete_new[2]', subject: 'daily recap delete'
  end
  every :day, at: '6am' do
    rake 'recap:ingest_new[2]', subject: 'daily recap ingest'
  end
  # #  Add authority variants after each daily load 
  # every :day, at: '4am' do
  #   rake 'authorities:add_to_bib:by_extract[recap]', subject: 'daily recap authorities'
  # end

  # == LAW ==

  # Weekly full load of all Law records
  every :sunday, at: '8am' do
    rake 'bibliographic:extract:process EXTRACT=law', subject: 'law load'
  end

  # # Add authority variants to the Law records after each load
  # every :sunday, at: '10am' do
  #   rake 'authorities:add_to_bib:by_extract[law]', subject: 'weekly law authorities'
  # end

  # # Weekly Delete of all stale Law records (3 week grace period)
  # # (TODO: this should definitely be coded into a rake task!)
  # every :sunday, at: '10am' do
  #   command '/usr/bin/curl --silent "http://lito-solr-dev1.cul.columbia.edu:8983/solr/clio_dev/update?commit=true" -H "Content-Type: text/xml" --data-binary "<delete><query>timestamp:[* TO NOW/DAY-21DAYS] AND location_facet:Law</query></delete>"', subject: 'law purge'
  # end


  # Fetch a fresh "full" extract, once a week.
  # We'll run this in bits througout the month
  every :saturday, at: '10am' do
    rake 'bibliographic:extract:fetch EXTRACT=full', subject: 'weekly fetch full'
  end

end

# Anything for PROD only?
if ['clio_prod'].include?(@environment)

  #   RECAP
  # Only download ReCAP extract files from SCSB once.
  # Then each environment can index from this local location individually.
  every :day, at: '11:30pm' do
    rake 'recap:download', subject: 'recap download'
  end
  
end



