# The SimplyE daily batch should:
# - fetch a remote data file
# --- if failure, abort and notify
# - validate the data file
# --- if failure, abort and notify
# 
# - load the current datastore
# - figure out adds/deletes/modifies/unchanged
# - foreach add, add
# - foreach delete, delete
# - foreach modify, modify
# - notify final report via email
# ---- header of totals, and adds/deletes/modifies
# ---- detail of specific list of adds/deletes/modifies

require 'net/scp'
require 'csv'


namespace :simplye do

  ##############################################################
  desc 'fetch simplye data file'
  task :fetch do
    setup_ingest_logger
    Rails.logger.info("===  fetching SimplyE datafile  ===")
    remote_file = APP_CONFIG['simplye']['scp_remote_path'] + '/' + APP_CONFIG['simplye']['data_file']
    local_file  = APP_CONFIG['extract_home'] + '/simplye/' + APP_CONFIG['simplye']['data_file']

    Rails.logger.info("-- fetching...")      
    Net::SCP.download!(
      APP_CONFIG['simplye']['scp_remote_host'],
      APP_CONFIG['simplye']['scp_username'],
      remote_file,
      local_file,
    )
    if File.exist?(local_file)
      Rails.logger.info("-- fetched.")      
    else
      abort("ERROR:  local download file #{local_file} does not exist!")
    end
    
  end

  ##############################################################
  desc 'validate simplye data file'
  task :validate do
    setup_ingest_logger
    Rails.logger.info("===  validating SimplyE datafile  ===")

    Rails.logger.info("-- validating...")      
    local_file  = APP_CONFIG['extract_home'] + '/simplye/' + APP_CONFIG['simplye']['data_file']
    rows = CSV.read(local_file)
    rows.each do |row|
      # skip header row - hardcode expected values
      next if row[0] == 'BIBID' && row[1] == 'HREF'
      # skip if data row - integer ID, URL
      next if row[0].match(/^\d+$/) && row[1].starts_with?('https://')
      # Anything else?  Error.
      abort("ERROR:  unexpected data in SimplyE datafile [#{local_file}]:\n#{row[0]},#{row[1]}")
    end
    Rails.logger.info("-- validated.")      

  end

  ##############################################################
  desc 'SimplyE feed - full processing cycle'
  task :process  => :environment do
    setup_ingest_logger
    Rails.logger.info("====>>>  START simplye:process  <<<====")

    local_file  = APP_CONFIG['extract_home'] + '/simplye/' + APP_CONFIG['simplye']['data_file']
    
    begin
      # Rake::Task['simplye:fetch'].invoke
      Rake::Task['simplye:validate'].invoke
      
      
      current_links = SimplyeLink.all()
      Rails.logger.info("-- current: #{current_links.size} SimplyE links.")

      new_links = Hash.new()
      rows = CSV.read(local_file)
      rows.each do |row|
        # skip header row if present - hardcode expected values
        next if row[0] == 'BIBID' && row[1] == 'HREF'
        new_links[ row[0] ] = row[1]
      end
      Rails.logger.info("-- new: #{new_links.size} SimplyE links.")

      updates = {}
      deletes = {}
      as_is = {}
      # detect any current rows which are updated or deleted
      current_links.each do |current_link|
        bib_id = current_link['bib_id']
        
        # If the bib is missing from the new data file, it's a delete
        if not new_links[bib_id]
          deletes[bib_id] = current_link['simplye_url'] 
          next
        end
        
        # If the data file has a new URL for a bib, it's an update
        if new_links[bib_id] && (new_links[bib_id] != current_link['simplye_url'])
          updates[bib_id] = new_links[bib_id]
          next
        end
        
        # Keep track of unchanged existing links, for "adds" detection below
        as_is[bib_id] = current_link['simplye_url'] 
      end

      # detect any new rows which are adds
      adds = {}
      new_links.each_pair do |bib_id, simplye_url|
        next if updates[bib_id] || deletes[bib_id] || as_is[bib_id]
        adds[bib_id] = simplye_url
      end 

      Rails.logger.info("-- found #{adds.size} adds, #{updates.size} updates, and #{deletes.size} deletes")
      
      body = %Q(
===  SimplyE Processing  ===
Found #{current_links.size} existing SimplyE links.
Found #{new_links.size} SimplyE links in data feed.
Changes detection found #{adds.size} adds, #{updates.size} updates, and #{deletes.size} deletes.
        
      )

      body = body + "\n-- Adds (#{adds.size}) --\n"
      adds.each_pair do |bib_id, simplye_url|
        body = body + "#{bib_id},#{simplye_url}\n"
        SimplyeLink.create(bib_id: bib_id, simplye_url: simplye_url)
      end

      body = body + "\n-- Updates (#{updates.size}) --\n"
      updates.each_pair do |bib_id, simplye_url|
        body = body + "#{bib_id},#{simplye_url}\n"
        SimplyeLink.find_by(bib_id: bib_id).update(simplye_url: simplye_url)
      end

      body = body + "\n-- Deletes (#{deletes.size}) --\n"
      deletes.each_pair do |bib_id, simplye_url|
        body = body + "#{bib_id},#{simplye_url}\n"
        SimplyeLink.find_by(bib_id: bib_id).destroy
      end

    ensure
      # No matter what happened, generate an output email notification
      Rails.logger.info('-- sending notification email...')
      notification_email = RakeMailer.rake_mail(
          to:           'marquis@columbia.edu',
          subject:      'SimplyE Processing Notification',
          body:         body,
          content_type: 'text/plain',
      )
      notification_email.deliver_now
      
      Rails.logger.info('-- mail sent.')
    end
  end


end
