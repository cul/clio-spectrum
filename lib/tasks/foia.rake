
# [litoserv@libsys-service-prod1 ~]$ aws s3 ls s3://cul-s3-clio-foia --profile "default"
# 2020-06-20 17:36:48 8439365925 cfpf-full.xml
# 2020-06-17 20:01:03  197716636 clinton-full.xml
# 2020-06-17 17:11:22  847462789 frus-full.xml
# 2020-06-17 18:14:43   14057013 pdb-full.xml
#

namespace :foia do

  ##############################################################
  desc 'list FOIA files available for download from S3 bucket'
  task :list_bucket do
    setup_ingest_logger
    Rails.logger.info('- listing remote files from S3 bucket')
    
    Rails.logger.info('- creating S3 client connection')
    s3 = get_s3

    Rails.logger.info("- list objects in bucket #{FOIA_BUCKET}")
    list = s3.list_objects(bucket: FOIA_BUCKET)
    list.contents.each do |object|
      filename = object.key
      bytes = object.size
      mbs = bytes / (1024 * 1024)
      Rails.logger.info sprintf("    %-20s %5dM", filename, mbs.round(0))
    end
    Rails.logger.info("- list complete, #{list.contents.size} files found.")
  end

  ##############################################################
  desc 'list already-downloaded FOIA files from extract directory'
  task :list do
    setup_ingest_logger
    Rails.logger.info('- listing already-downloaded FOIA files')
    Rails.logger.info('-   (use foia:list_bucket to list files in AWS S3 bucket)')
    
    extract_dir = APP_CONFIG['extract_home'] + '/' + 'foia'

    Rails.logger.info("- listing files from #{extract_dir}")
    file_list = Dir.glob("#{extract_dir}/*.xml").sort
    file_list.each do |filename|
      bytes = File.size(filename)
      mbs = bytes / (1024 * 1024)
      Rails.logger.info sprintf("    %-20s %5dM", File.basename(filename), mbs.round(0))
    end
    Rails.logger.info("- list complete, #{file_list.size} files found.")
  end

  ##############################################################
  desc 'download all FOIA files from S3 bucket to local storage'
  task :download_all do
    setup_ingest_logger

    # Just pull everything down, sort it out locally.
    Rails.logger.info('- downloading ALL remote FOIA files')
    
    Rails.logger.info('- creating S3 client connection')
    s3 = get_s3
    
    Rails.logger.info('- getting list of files')
    list = s3.list_objects(bucket: FOIA_BUCKET)
  
    Rails.logger.info("- downloading #{list.contents.size} files...")
    
    list.contents.each do |object|
      filename = object.key
      Rails.logger.info('-' * 60)
      Rake::Task['foia:download_file'].reenable
      Rake::Task['foia:download_file'].invoke(filename, s3)
    end
    Rails.logger.info('-' * 60)
    
    Rails.logger.info("- finished processing #{list.contents.size} files.")
  end
    

  ##############################################################
  desc 'download a single specified FOIA file from S3'
  task :download_file, [:filename, :s3] => :environment do |_t, args|
    setup_ingest_logger

    extract_dir = APP_CONFIG['extract_home'] + '/' + 'foia'

    # Rails.logger.debug('---- turning off http(s)_proxy (squid)')
    # ENV.delete('http_proxy')
    # ENV.delete('https_proxy')

    # process input parameters
    filename = args[:filename]
    abort('foia:download_file[:filename] not passed filename!') unless filename
    s3 = args[:s3]
    unless (s3)
      Rails.logger.info('--- creating S3 client connection')
      s3 = get_s3
    end
    
    downloaded_file = "#{extract_dir}/#{filename}"
    
    # validate passed filename
    Rails.logger.info("--- verifying filename #{filename}")
    objectsize = nil
    begin
      response = s3.list_objects(bucket: FOIA_BUCKET, prefix: filename)
      objectsize = response.contents.first.size
    rescue
      abort("Unable to find file '#{filename}' in s3 bucket '#{FOIA_BUCKET}'")
    end
    
    # download the file
    Rails.logger.info("--- downloading file: #{filename} from s3 bucket")
    Rails.logger.info("--- saving to extract diretory #{extract_dir}")
    response = s3.get_object(
        response_target: downloaded_file,
        bucket: FOIA_BUCKET, 
        key: filename,
    )
    Rails.logger.info("--- download of #{filename} complete.")
    
    # verify the downloaded file
    filesize = File.size(downloaded_file)
    if (objectsize == filesize)
      Rails.logger.info("--- verified that bytesize of download matches s3")
      Rails.logger.info("---   (objectsize = #{objectsize} / filesize = #{filesize})")
    else
      abort("ERROR:  downloaded filesize doesn't match object size")
    end
    
    # delete the file from the s3 bucket
    Rails.logger.info("--- deleting #{filename} from s3 bucket...")
    
    response = s3.delete_object(bucket: FOIA_BUCKET, key: filename)
    # Rails.logger.debug(response.inspect)
    
    # verify that the object is no longer found in the S3 bucket
    response = s3.list_objects(bucket: FOIA_BUCKET, prefix: filename)
    abort("ERROR:  file #{filename} still found in s3 bucket after delete") unless response && response.contents && response.contents.size == 0
    
    Rails.logger.info("--- deleted.")
    
  end


  ##############################################################
  desc 'Ingest all available FOIA MARC XML files'
  task :ingest_all do
    setup_ingest_logger
    Rails.logger.info('-- ingesting all available FOIA files to Solr...')
    
    extract_dir = APP_CONFIG['extract_home'] + '/' + 'foia'
    
    # Get list of all FOIA files
    all_files = Dir.glob("#{extract_dir}/*.xml").map { |f| File.basename(f) }.sort
    if (all_files.size > 0)
      Rails.logger.info("-- found #{all_files.size} FOIA XML files to ingest")
    else      
      abort("ERROR: can't find any xml files under #{extract_dir}") 
    end

    all_files.each do |filename|
      Rails.logger.info('-' * 60)
      Rake::Task['foia:ingest_file'].reenable
      Rake::Task['foia:ingest_file'].invoke(filename)
    end
    Rails.logger.info('-' * 60)
    
    Rails.logger.info('-- ingest of all files complete.')
    
  end
  

  ##############################################################
  desc 'ingest a single FOIA MARC XML file'
  task :ingest_file, [:filename] do |_t, args|
    setup_ingest_logger

    filename = args[:filename]
    extract_dir = APP_CONFIG['extract_home'] + '/' + 'foia'

    abort('ERROR: foia:ingest_file[:filename] not passed filename') unless filename
    abort("ERROR: foia:ingest_file[:filename] passed non-existant filename #{filename}") unless File.exist?("#{extract_dir}/#{filename}")
    abort('ERROR: foia:ingest_file[:filename] not an XML file') unless filename.ends_with?('.xml')

    Rails.logger.info("--- ingesting FOIA file #{filename}")

    # get the environment-specific file-ingest directory in shape
    current_dir = File.join(Rails.root, 'tmp/extracts/foia/current/')
    old_dir = File.join(Rails.root, 'tmp/extracts/foia/old')
    FileUtils.mkdir_p(current_dir)
    FileUtils.mkdir_p(old_dir)

    # roll previous-load of same filename aside, copy in newest version
    FileUtils.rm("#{old_dir}/#{filename}") if File.exist?("#{old_dir}/#{filename}")
    FileUtils.mv("#{current_dir}/#{filename}", "#{old_dir}/#{filename}") if File.exist?("#{current_dir}/#{filename}")
    FileUtils.cp("#{extract_dir}/#{filename}", current_dir)

    Rails.logger.info('--- calling bibliographic:extract:ingest')
    ENV['EXTRACT'] = 'foia'
    # re-enable, in case we're calling this task repeatedly in a loop
    Rake::Task['bibliographic:extract:ingest'].reenable
    Rake::Task['bibliographic:extract:ingest'].invoke

    Rails.logger.info("--- ingest #{filename} done.")
  end
  

  ##############################################################
  desc 'delete stale FOIA records from the solr index'
  task prune_index: :environment do
    setup_ingest_logger
    Rails.logger.info('-- pruning index...')

    solr_url = Blacklight.connection_config[:indexing_url] ||
               Blacklight.connection_config[:url]
    solr_connection = RSolr.connect(url: solr_url)

    if ENV['STALE_DAYS'] && ENV['STALE_DAYS'].to_i < 30
      puts "ERROR: Environment variable STALE_DAYS set to [#{ENV['STALE_DAYS']}]"
      puts 'ERROR: Should be > 30, or unset to allow default setting.'
      puts 'ERROR: Skipping prune_index step.'
      next
    end
    # default - one full year
    stale = (ENV['STALE_DAYS'] || 360).to_i
    Rails.logger.info("-- pruning records older than [ #{stale} ] days.")
    # TODO: - SOLR RECORDS SHOULD SELF-IDENTIFY AS VOYAGER FEED RECORDS
    query = "timestamp:[* TO NOW/DAY-#{stale}DAYS] AND id:FOIA*"
    puts "DEBUG query=#{query}" if ENV['DEBUG']

    # To be safe, refuse to delete over N records
    response = solr_connection.get 'select', params: { q: query, rows: 0 }
    numFound = response['response']['numFound'].to_i

    Rails.logger.info("-- found #{numFound} stale records.")

    prune_limit = (ENV['PRUNE_LIMIT'] || 10000).to_i
    if numFound > prune_limit
      message = "ERROR:  prune limit set to #{prune_limit}, found [#{numFound}] stale records - skipping!"
      Rails.logger.error("-- #{message}")
      puts message
    else
      if numFound > 0
        Rails.logger.info('-- pruning...')
        solr_connection.delete_by_query query
        solr_connection.commit
      end
    end
    Rails.logger.info('-- pruning complete.')
  end



end


def get_s3
  abort("AWS connection details not found in app_config") unless APP_CONFIG['aws']
  aws_access_key_id = APP_CONFIG['aws']['access_key_id']
  aws_secret_access_key = APP_CONFIG['aws']['secret_access_key']
  aws_region = APP_CONFIG['aws']['region']
  abort("AWS connection details not found in app_config") unless aws_access_key_id && aws_secret_access_key && aws_region

  credentials = Aws::Credentials.new(aws_access_key_id, aws_secret_access_key)
  s3 = Aws::S3::Client.new(region: aws_region, credentials: credentials)

  s3
end

