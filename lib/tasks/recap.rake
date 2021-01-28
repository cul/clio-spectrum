

# ReCAP files are zips
# filename is something like:  PUL-NYPL_20171015_225400.zip
# The timestamp is unpredictable.
# Within the zip are an unknown number of XML files.
# ls |sort -n
# 3.xml     6.xml    9.xml    12.xml
# Oddly non-sequential.
# HTC hasn't made any guarantees about filenames or retention.
#
# So, how do we batch process?
# 1) download whatever we find?
# 2) keep local copy of everything?
# 3) identify the newest filename and process?
# 3) or track files and process any that we haven't yet done?
# 4) unzip to empty directory
# 5) ingest the full directory contents

namespace :recap do
  ##############################################################
  desc 'list files available for download from recap'
  task :list do
    setup_ingest_logger
    storage_service = APP_CONFIG['recap']['storage_service'] || ''
    Rails.logger.info("- recap storage service set to: #{storage_service}")
    
    if storage_service == 'sftp'
      Rake::Task['recap:list_sftp'].invoke
    elsif storage_service == 'aws'
      Rake::Task['recap:list_aws'].invoke
    else
      abort("ERROR: unknown/undefined recap storage_service [#{storage_service}]")
    end
  end

  ##############################################################
  task :list_sftp do
    setup_ingest_logger
    Rails.logger.info('- listing remote files on ReCAP SFTP server')
    sftp = get_recap_sftp
    # list the entries in a directory
    count = 0
    files = sftp.dir.entries(APP_CONFIG['recap']['sftp_path'])
    files.sort { |f1, f2| f1.attributes.mtime <=> f2.attributes.mtime }.each do |file|
      puts file.longname
      count += 1
    end
    Rails.logger.info("- done.  #{files.size} files found.")
  end

  ##############################################################
  task :list_aws do
    setup_ingest_logger
    bucket = APP_CONFIG['recap']['aws_bucket']
    prefix = APP_CONFIG['recap']['aws_prefix']

    Rails.logger.info('- listing remote files from ReCAP S3 bucket')
    
    Rails.logger.info('- creating S3 client connection')
    s3 = get_recap_s3

    Rails.logger.info("- list objects in bucket #{bucket}, prefix #{prefix}")
    count = 0
    list = s3.list_objects(bucket: bucket, prefix: prefix)
    list.contents.each do |object|
      filename = object.key
      # skip "directories", which end with a slash
      next if filename.match(/\/$/)
      count += 1
      bytes = object.size
      kbs = bytes / 1024
      puts sprintf("%5dK   %-20s", kbs.round(0), filename)
    end
    Rails.logger.info("- list complete, #{count} files found.")
  end


  ##############################################################
  desc 'download all new ReCAP update/full/delete files to local storage'
  task :download do
    setup_ingest_logger

    # Just pull everything down, sort it out locally.
    Rails.logger.info('- downloading ALL remote ReCAP files')
    extract_dir = APP_CONFIG['extract_home'] + '/' + 'recap'
    Rails.logger.info("- saving files beneath #{extract_dir}")


    # HTC puts update files in one directory, delete files in another.
    # And the directories are named after file-formats, not functions...
    storage_service = APP_CONFIG['recap']['storage_service'] || ''
    # Rails.logger.info("- recap storage service set to: #{storage_service}")
    if storage_service == 'sftp'
      incremental_dir = APP_CONFIG['recap']['sftp_incremental_dir']
      full_dir = APP_CONFIG['recap']['sftp_full_dir']
      deletes_dir = APP_CONFIG['recap']['sftp_deletes_dir']
    end
    if storage_service == 'aws'
      incremental_dir = APP_CONFIG['recap']['aws_incremental_dir']
      full_dir = APP_CONFIG['recap']['aws_full_dir']
      deletes_dir = APP_CONFIG['recap']['aws_deletes_dir']
    end

    unless extract_dir && incremental_dir && full_dir && deletes_dir
      abort("ERROR: app_config 'recap' section missing sftp params!")
    end

    # Repeat the same download steps, for Updates, for Fulls, and for Deletes
    Rake::Task['recap:download_dir'].reenable
    Rake::Task['recap:download_dir'].invoke('Updates', incremental_dir)

    Rake::Task['recap:download_dir'].reenable
    Rake::Task['recap:download_dir'].invoke('Fulls', full_dir)

    Rake::Task['recap:download_dir'].reenable
    Rake::Task['recap:download_dir'].invoke('Deletes', deletes_dir)

    Rails.logger.info('- complete.')
  end

  ##############################################################
  desc 'download all new files from a specific remote directory'
  task :download_dir, [:label, :directory] do |_t, args|
    setup_ingest_logger

    label = args[:label]
    directory = args[:directory]

    Rails.logger.info("-- downloading #{label} files (from '#{directory}') dir...")

    storage_service = APP_CONFIG['recap']['storage_service'] || ''
    Rails.logger.info("- recap storage service set to: #{storage_service}")
    
    if storage_service == 'sftp'
      Rake::Task['recap:download_dir_sftp'].reenable
      Rake::Task['recap:download_dir_sftp'].invoke(label, directory)
    elsif storage_service == 'aws'
      Rake::Task['recap:download_dir_aws'].reenable
      Rake::Task['recap:download_dir_aws'].invoke(label, directory)
    else
      abort("ERROR: unknown/undefined recap storage_service [#{storage_service}]")
    end
    
  end
  

  ##############################################################
  desc 'download all new files from a specific remote SFTP directory'
  task :download_dir_sftp, [:label, :directory] do |_t, args|
    setup_ingest_logger

    label = args[:label]
    directory = args[:directory]

    sftp_path = APP_CONFIG['recap']['sftp_path']
    recap_extract_home = APP_CONFIG['extract_home'] + '/recap'

    full_sftp_path = sftp_path + '/' + directory
    full_local_path = recap_extract_home + '/' + directory
    puts "DEBUG full_sftp_path=[#{full_sftp_path}]" if ENV['DEBUG']
    puts "DEBUG full_local_path=[#{full_local_path}]" if ENV['DEBUG']
    Rails.logger.info("-- saving to local dir #{full_local_path}")

    sftp = get_recap_sftp
    already_have = []
    need_to_download = []

    files = sftp.dir.entries(full_sftp_path)
    files.each do |file|
      if File.exist?("#{full_local_path}/#{file.name}")
        already_have << file.name
      else
        need_to_download << file.name
      end
    end

    Rails.logger.info("--- found #{already_have.size + need_to_download.size} files")
    Rails.logger.info("--- already have #{already_have.size} files")
    Rails.logger.info("--- need to download #{need_to_download.size} files")

    need_to_download.sort.each do |filename|
      Rails.logger.info("--- fetching #{filename}...")
      sftp.download!("#{full_sftp_path}/#{filename}", "#{full_local_path}/#{filename}")
    end

    Rails.logger.info("-- done.  downloaded #{need_to_download.size} new files.")
  end

  ##############################################################
  desc 'download all new files from a specific remote AWS S3 directory'
  task :download_dir_aws, [:label, :directory] do |_t, args|
    setup_ingest_logger

    label = args[:label]
    directory = args[:directory]

    aws_prefix = APP_CONFIG['recap']['aws_prefix']
    aws_prefix += '/' unless aws_prefix.ends_with?('/')
    recap_extract_home = APP_CONFIG['extract_home'] + '/recap'

    puts "DEBUG aws_prefix=[#{aws_prefix}]" if ENV['DEBUG']
    puts "DEBUG directory=[#{directory}]" if ENV['DEBUG']

    full_aws_prefix = aws_prefix + directory
    full_aws_prefix += '/' unless full_aws_prefix.ends_with?('/')
    full_local_path = recap_extract_home + '/' + directory
    puts "DEBUG full_aws_prefix=[#{full_aws_prefix}]" if ENV['DEBUG']
    puts "DEBUG full_local_path=[#{full_local_path}]" if ENV['DEBUG']
    Rails.logger.info("-- saving to local dir #{full_local_path}")

    Rails.logger.info('- creating S3 client connection')
    s3 = get_recap_s3

    already_have = []
    need_to_download = []

    Rails.logger.info('- getting list of files')
    bucket = APP_CONFIG['recap']['aws_bucket']
    list = s3.list_objects(bucket: bucket, prefix: full_aws_prefix)

    list.contents.each do |object|
      # filename is full AWS S3 filename to file
      filename = object.key
      # skip "directories", which end with a slash
      next if filename.match(/\/$/)
      remote_size = object.size
      basename = File.basename(filename)
      local_file = "#{full_local_path}/#{basename}"
      puts "DEBUG filename=[#{filename}] basename=[#{basename}]" if ENV['DEBUG']
      
      if File.exist?(local_file)
        local_size = File.size(local_file)
        if local_size != remote_size
          abort("ERROR:  we already have #{basename}, but size does not match remote!")
        end
        already_have << basename
      else
        need_to_download << filename
      end
    end

    Rails.logger.info("--- found #{already_have.size + need_to_download.size} files")
    Rails.logger.info("--- already have #{already_have.size} files")
    Rails.logger.info("--- need to download #{need_to_download.size} files")

    need_to_download.sort.each do |filename|
      basename = File.basename(filename)
      local_file = "#{full_local_path}/#{basename}"

      Rails.logger.info("--- fetching #{basename}...")      
      puts "DEBUG local_file=[#{local_file}]" if ENV['DEBUG']
      puts "DEBUG bucket=[#{bucket}]" if ENV['DEBUG']
      puts "DEBUG filename=[#{filename}]" if ENV['DEBUG']
      s3.get_object(response_target: local_file, bucket: bucket, key: filename)
      
      # verify
      response = s3.list_objects(bucket: bucket, prefix: filename)
      remote_size = response.contents.first.size
      local_size = File.size(local_file)
      if local_size != remote_size
        abort("ERROR:  fetch #{basename} complete, but size does not match remote!")
      end

    end

    Rails.logger.info("-- done.  downloaded #{need_to_download.size} new files.")
  end


  ##############################################################
  desc 'run deletes from a single ReCAP zip file'
  task :delete_file, [:filename] do |_t, args|
    setup_ingest_logger

    filename = args[:filename]

    sftp_deletes_dir = APP_CONFIG['recap']['sftp_deletes_dir']
    abort('ERROR: app_config missing recap/sftp_deletes_dir!') unless sftp_deletes_dir
    extract_home = APP_CONFIG['extract_home']
    abort('ERROR: app_config missing extract_home!') unless extract_home

    extract_dir = APP_CONFIG['extract_home'] + '/recap/' + sftp_deletes_dir
    full_path = extract_dir + '/' + filename

    abort('recap:ingest[:filename] not passed filename!') unless filename
    abort("recap:ingest[:filename] passed non-existant filename #{filename}") unless File.exist?(full_path)
    abort('recap:ingest[:filename] not a ReCAP .zip extract file!') unless filename.ends_with?('.zip')

    Rails.logger.info("- deleting from ReCAP file #{filename}")

    deletes_dir = File.join(Rails.root, 'tmp/extracts/recap/deletes/')
    FileUtils.rm_rf(deletes_dir)
    FileUtils.mkdir_p(deletes_dir)

    unzip_command = "/usr/bin/unzip #{full_path} -d #{deletes_dir}"
    Rails.logger.info("--- unzipping #{filename} to #{deletes_dir}")
    if system(unzip_command)
      Rails.logger.info('--- unzip successful')
    else
      Rails.logger.error('--- unzip unsucessful')
      abort('Unzip unsucessful')
    end

    # The ReCAP deletes file is a JSON format file named "0.json"
    # (this appears to be consistent)
    # We need to read the json and write out CLIO bib ids to delete, into
    # the expected "delete_keys.txt"
    json_file = deletes_dir + '0.json'
    abort("ERROR: unzipped ReCAP deletes file #{json_file} not found!") unless File.exist?(json_file)

    Rails.logger.info('--- parsing ReCAP JSON deletes file...')
    deletes_structure = JSON.parse(File.read(json_file))
    abort("ERROR: ReCAP deletes file #{json_file} unparsable!") unless deletes_structure && deletes_structure.is_a?(Array)

    # A ReCAP deletes file looks like this:
    # [
    #   {
    #     "bib": {
    #       "bibId": "8802046",
    #       "owningInstitutionBibId": "10155102",
    #       "owningInstitutionCode": "PUL",
    #       "deleteAllItems": true,
    #       "items": null
    #     }
    #   },
    #   {
    #     ...
    #   },
    #   ...
    # ]
    # All we care about is the "bibId", which is the "SCSB-9999" bib number in CLIO.

    delete_keys = deletes_structure.map do |bib_structure|
      bib_attribute_hash = bib_structure['bib']
      bibId = bib_attribute_hash['bibId']
      "SCSB-#{bibId}"
    end
    Rails.logger.info("--- found #{delete_keys.size} keys to delete.")
    # puts delete_keys # DEBUG

    current_dir = File.join(Rails.root, 'tmp/extracts/recap/current/')
    FileUtils.mkdir_p(current_dir)
    deletes_file = current_dir + 'delete_keys.txt'
    # sample write-to-file code:
    Rails.logger.info('--- writing out to CLIO-format delete_keys.txt file...')
    File.open(deletes_file, 'w') do |f|
      delete_keys.sort.each do |delete_key|
        f.puts delete_key
      end
    end

    Rails.logger.info('--- calling bibliographic:extract:deletes')
    ENV['EXTRACT'] = 'recap'
    # re-enable, in case we're calling this task repeatedly in a loop
    Rake::Task['bibliographic:extract:deletes'].reenable
    Rake::Task['bibliographic:extract:deletes'].invoke
    Rails.logger.info('--- complete.')
  end

  ##############################################################
  desc "delete from new ReCAP .zip files that haven't yet been delete"
  task :delete_new, [:count] do |_t, args|
    setup_ingest_logger

    count = (args[:count] || '1').to_i
    Rails.logger.info("- delete_new - deleting from up to #{count} new files.")

    sftp_deletes_dir = APP_CONFIG['recap']['sftp_deletes_dir']
    abort('ERROR: app_config missing recap/sftp_deletes_dir!') unless sftp_deletes_dir
    extract_home = APP_CONFIG['extract_home']
    abort('ERROR: app_config missing extract_home!') unless extract_home

    extract_dir = extract_home + '/recap/' + sftp_deletes_dir

    # read in our 'last-delete-file' file - or abort if not found.
    # this file tells us the last file that was deleted from.
    last_delete_file = extract_dir + "/last-delete.#{Rails.env}.txt"
    abort("Can't find last-delete-file #{last_delete_file}") unless File.exist?(last_delete_file)
    Rails.logger.info("--- found last_delete_file: #{last_delete_file}")

    last_delete = File.read(last_delete_file).strip
    abort("Cannot find last-delete in last-delete-file #{last_delete_file}") if last_delete.blank?
    Rails.logger.info("--- last delete: #{last_delete}")

    # retrieve the list of files, sorted (alphanumeric sort == chronological sort)
    all_files = Dir.glob("#{extract_dir}/PUL-NYPL*.zip").map { |f| File.basename(f) }.sort
    abort("Can't find any delete files in #{extract_dir}") if all_files.size.zero?
    Rails.logger.info("--- found #{all_files.size} total files.")
    # puts all_files.inspect  # DEBUG

    # identify files that came after the last-delete-file
    new_files = all_files.select { |file| file > last_delete }
    Rails.logger.info("--- found #{new_files.size} new files since last delete.")

    if new_files.size.zero?
      Rails.logger.info("- No new files to delete!  (Did you run 'recap:download' first?).")
      exit
    end

    if count != new_files.size
      Rails.logger.warn("--- warning: requested delete of #{count} files, but #{new_files.size} new files found.")
    end

    # For each file in the list, delete it.
    files_to_delete = new_files[0, count]
    files_to_delete.each do |filename|
      Rails.logger.info('-' * 60)
      Rails.logger.info("--- Rake::Task[recap:delete_file].invoke(#{filename})")
      Rails.logger.info('-' * 60)
      Rake::Task['recap:delete_file'].reenable
      Rake::Task['recap:delete_file'].invoke(filename)

      # Now, record what we've done by writing out the last-deleteed filename
      Rails.logger.info("--- updating #{last_delete_file} with latest delete (#{filename})")
      File.open(last_delete_file, 'w') do |f|
        f.puts(filename)
      end
    end
    Rails.logger.info('-' * 60)

    Rails.logger.info('- delete_new complete.')
  end

  ##############################################################
  desc 'ingest a single ReCAP zip file'
  task :ingest_file, [:filename] do |_t, args|
    setup_ingest_logger

    filename = args[:filename]

    sftp_incremental_dir = APP_CONFIG['recap']['sftp_incremental_dir']
    abort('ERROR: app_config missing recap/sftp_incremental_dir!') unless sftp_incremental_dir
    extract_home = APP_CONFIG['extract_home']
    abort('ERROR: app_config missing extract_home!') unless extract_home

    extract_dir = APP_CONFIG['extract_home'] + '/recap/' + sftp_incremental_dir
    full_path = extract_dir + '/' + filename

    abort('recap:ingest_file[:filename] not passed filename!') unless filename
    abort("recap:ingest_file[:filename] passed non-existant filename #{filename}") unless File.exist?(full_path)
    abort('recap:ingest_file[:filename] not a ReCAP .zip extract file!') unless filename.ends_with?('.zip')

    Rails.logger.info("- ingesting ReCAP file #{filename}")

    # get extracts directories ready

    current_dir = File.join(Rails.root, 'tmp/extracts/recap/current/')
    temp_old_dir_name = File.join(Rails.root, 'tmp/extracts/recap/old')

    FileUtils.rm_rf(temp_old_dir_name)
    FileUtils.mv(current_dir, temp_old_dir_name) if File.exist?(current_dir)
    FileUtils.mkdir_p(current_dir)
    unzip_command = "/usr/bin/unzip #{full_path} -d #{current_dir}"
    Rails.logger.info("--- unzipping #{filename} to #{current_dir}")
    if system(unzip_command)
      Rails.logger.info('--- unzip successful')
    else
      Rails.logger.error('--- unzip unsucessful')
      abort('Unzip unsucessful')
    end

    Rails.logger.info('--- calling bibliographic:extract:ingest')
    ENV['EXTRACT'] = 'recap'
    # re-enable, in case we're calling this task repeatedly in a loop
    Rake::Task['bibliographic:extract:ingest'].reenable
    Rake::Task['bibliographic:extract:ingest'].invoke
    Rails.logger.info('--- complete.')
  end

  ##############################################################
  desc "ingest new ReCAP .zip files that haven't yet been ingested"
  task :ingest_new, [:count] do |_t, args|
    setup_ingest_logger

    count = (args[:count] || '1').to_i
    Rails.logger.info("- ingest_new - ingesting up to #{count} new files.")

    sftp_incremental_dir = APP_CONFIG['recap']['sftp_incremental_dir']
    abort('ERROR: app_config missing recap/sftp_incremental_dir!') unless sftp_incremental_dir
    extract_home = APP_CONFIG['extract_home']
    abort('ERROR: app_config missing extract_home!') unless extract_home

    extract_dir = extract_home + '/recap/' + sftp_incremental_dir

    # read in our 'last-*-file' file - or abort if not found.
    # this file tells us the last file that was ingested.
    last_incremental_file = extract_dir + "/last-incremental.#{Rails.env}.txt"
    abort("Can't find last-incremental-file #{last_incremental_file}") unless File.exist?(last_incremental_file)
    Rails.logger.info("--- found last_incremental_file: #{last_incremental_file}")

    last_incremental = File.read(last_incremental_file).strip
    abort("Cannot find last-incremental in last-incremental-file #{last_incremental_file}") if last_incremental.blank?
    Rails.logger.info("--- last ingest: #{last_incremental}")

    # retrieve the list of files, sorted (alphanumeric sort == chronological sort)
    all_files = Dir.glob("#{extract_dir}/PUL-NYPL*.zip").map { |f| File.basename(f) }.sort
    abort("Can't find any ingest files in #{extract_dir}") if all_files.size.zero?
    Rails.logger.info("--- found #{all_files.size} total files.")
    # puts all_files.inspect

    # identify files that came after the last-incremental-file
    new_files = all_files.select { |file| file > last_incremental }
    Rails.logger.info("--- found #{new_files.size} new files since last ingest.")

    if new_files.size.zero?
      Rails.logger.info("- No new files to ingest!  (Did you run 'recap:download' first?).")
      exit
    end

    if count != new_files.size
      Rails.logger.warn("--- warning: requested ingest of #{count} files, but #{new_files.size} new files found.")
    end

    # For each file in the list, ingest it.
    files_to_ingest = new_files[0, count]
    files_to_ingest.each do |filename|
      Rails.logger.info('-' * 60)
      Rails.logger.info("--- Rake::Task[recap:ingest_file].invoke(#{filename})")
      Rails.logger.info('-' * 60)
      Rake::Task['recap:ingest_file'].reenable
      Rake::Task['recap:ingest_file'].invoke(filename)

      # Now, record what we've done by writing out the last-incrementaled filename
      Rails.logger.info("--- updating #{last_incremental_file} with latest ingest (#{filename})")
      File.open(last_incremental_file, 'w') do |f|
        f.puts(filename)
      end
    end
    Rails.logger.info('-' * 60)

    Rails.logger.info('- recap:ingest_new complete.')
  end

  # Rails.logger.info("--- unzipping #{filename}...")
  # Rails.logger.info("/usr/bin/unzip #{extract_dir}/#{filename}")

  # namespace :fetch do
  #
  #   desc "fetch recap by filename [filename,local_dir]"
  #   task :filename, [:filename, :local_dir] do |t, args|
  #     setup_ingest_logger
  #     raise "recap:fetch:filename not passed filename!" unless args[:filename]
  #
  #     Rails.logger.info("- fetching ReCAP file #{args[:filename]}")
  #
  #     sftp = get_recap_sftp()
  #
  #     # download a file or directory from the remote host
  #     remote_file = APP_CONFIG['recap']['sftp_path'] + '/' + args[:filename]
  #     local_dir = args[:local_dir] || '/tmp'
  #     local_file = local_dir + '/' + args[:filename]
  #
  #     Rails.logger.info("--- downloading remote_file #{remote_file}")
  #     Rails.logger.info("--- to local_dir #{local_dir}")
  #
  #     sftp.download!(remote_file, local_file)
  #
  #     Rails.logger.info("--- done.  local file:")
  #     Rails.logger.info("/bin/ls -l #{local_dir}/#{args[:filename]}")
  #
  #
  #     Rails.logger.info("--- unzipping:")
  #     Rails.logger.info("/usr/bin/unzip #{local_dir}/#{args[:filename]}")
  #
  #     Rails.logger.info("- done.")
  #
  #   end
  #
  #   # :007 > s  = Net::SFTP.start('devops-recap.htcinc.com', 'recapftp', port: '2222', keys: ['/Users/marquis/.ssh/recapftp_rsa'] )
  #   #
  #   #  :004 > s.dir.foreach( '/share/recap/data-dump/prod/CUL/MarcXml') do |entry|
  #   #  :005 >     puts entry.longname
  #   #  :006?>   end
  #   # -rw-r--r--    1 1001     100           297 Sep 19 06:05 ExportDataDump_Full_PUL_20170918_230400.csv
  #   # -rw-r--r--    1 1001     100           298 Sep 19 10:16 ExportDataDump_Full_NYPL_20170919_022500.csv
  #   # -rw-r--r--    1 1001     100      937749743 Sep 19 06:05 PUL_20170918_230400.zip
  #   # -rw-r--r--    1 1001     100      1032238502 Sep 19 10:16 NYPL_20170919_022500.zip
  #   # drwxr-xr-x    2 1001     100          4096 Sep 19 10:16 .
  #   # drwxr-xr-x    3 1001     100          4096 Sep 19 06:05 ..
  #   #  => nil
  #   #
  # end
end


##############################################################
####  recap-specific support methods
##############################################################
def get_recap_sftp
  sftp_host = APP_CONFIG['recap']['sftp_host']
  sftp_user = APP_CONFIG['recap']['sftp_user']
  sftp_port = APP_CONFIG['recap']['sftp_port']
  sftp_keyfile = APP_CONFIG['recap']['sftp_keyfile']

  Rails.logger.info("--- opening SFTP connection to #{sftp_user}@#{sftp_host}:#{sftp_port}")
  sftp = Net::SFTP.start(sftp_host, sftp_user, port: sftp_port, keys: [sftp_keyfile])
  abort('get_recap_sftp() failed!') unless sftp

  sftp
end

##############################################################
def get_recap_s3
  aws_access_key_id = APP_CONFIG['recap']['aws_access_key_id']
  aws_secret_access_key = APP_CONFIG['recap']['aws_secret_access_key']
  aws_region = APP_CONFIG['recap']['aws_region']
  abort("AWS connection details for ReCAP not found in app_config") unless aws_access_key_id && aws_secret_access_key && aws_region

  credentials = Aws::Credentials.new(aws_access_key_id, aws_secret_access_key)

  options = { region: aws_region, credentials: credentials }
  options.merge!( {logger: Logger.new(STDERR), log_level: :debug} ) if ENV['DEBUG']

  s3 = Aws::S3::Client.new(options)

  s3
end


##############################################################





