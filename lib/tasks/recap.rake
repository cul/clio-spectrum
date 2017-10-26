

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


  desc "list files available for download from recap"
  task :list do
    setup_ingest_logger
    Rails.logger.info("- listing remote files on ReCAP SFTP server")
    sftp = get_sftp()
    # list the entries in a directory
    count = 0
    sftp.dir.foreach( APP_CONFIG['recap']['sftp_path'] ) do |entry|
      puts entry.longname
      count = count + 1
    end
    Rails.logger.info("- done.  #{count} files found.")
  end

  desc "download all new ReCAP extract files to local storage"
  task :download do
    setup_ingest_logger
    # fetch from this location
    sftp_path = APP_CONFIG['recap']['sftp_path']
    # Only retrieve files with this suffix
    suffix = "zip"
    Rails.logger.info("- downloading ALL remote ReCAP files with suffix #{suffix}")
    extract_dir = APP_CONFIG['extract_home'] + "/" + 'recap'
    Rails.logger.info("- saving files to  #{extract_dir}")

    sftp = get_sftp()
    already_have = []
    need_to_download  = []
    sftp.dir.glob(sftp_path, "*.#{suffix}") do |entry|
      if File.exist?("#{extract_dir}/#{entry.name}")
        already_have << entry.name
      else
        need_to_download << entry.name
      end
    end

    Rails.logger.info("--- found #{already_have.size + need_to_download.size} files")
    Rails.logger.info("--- already have #{already_have.size} files")
    Rails.logger.info("--- need to download #{need_to_download.size} files")
    need_to_download.sort.each do |filename|
      Rails.logger.info("--- fetching #{filename}...")
      sftp.download!("#{sftp_path}/#{filename}", "#{extract_dir}/#{filename}")
    end

    Rails.logger.info("- done.  downloaded #{need_to_download.size} new files.")
  end

  desc "ingest a single ReCAP zip file"
  task :ingest, [:filename] do |t, args|
    setup_ingest_logger

    filename = args[:filename]
    extract_dir = APP_CONFIG['extract_home'] + "/recap"
    full_path = extract_dir + '/' + filename

    raise "recap:ingest[:filename] not passed filename!" unless filename
    raise "recap:ingest[:filename] passed non-existant filename #{filename}" unless File.exist?(full_path)
    
    Rails.logger.info("- ingesting ReCAP file #{filename}")

    # get extracts directories ready

    current_dir = File.join(Rails.root, "tmp/extracts/recap/current/")
    temp_old_dir_name = File.join(Rails.root, "tmp/extracts/recap/old/")

    FileUtils.rm_rf(temp_old_dir_name)
    FileUtils.mv(current_dir, temp_old_dir_name) if File.exists?(current_dir)
    FileUtils.mkdir_p(current_dir)
    unzip_command = "/usr/bin/unzip #{full_path} -d #{current_dir}"
    Rails.logger.info("--- unzipping #{filename} to #{current_dir}")
    if system(unzip_command)
      Rails.logger.info("--- unzip successful")
    else
      Rails.logger.error("--- unzip unsucessful")
      raise "Unzip unsucessful"
    end    

    Rails.logger.info("--- calling bibliographic:extract:ingest")
    ENV['EXTRACT'] = 'recap'
    # re-enable, in case we're calling this task repeatedly in a loop
    Rake::Task["bibliographic:extract:ingest"].reenable
    Rake::Task["bibliographic:extract:ingest"].invoke
    Rails.logger.info("--- complete.")
  end


  desc "ingest new ReCAP zip files that haven't yet been ingested"
  task :ingest_new, [:count] do |t, args|
    setup_ingest_logger

    count = (args[:count] || '1').to_i
    Rails.logger.info("- ingest_new - ingesting up to #{count} new files.")

    extract_dir = APP_CONFIG['extract_home'] + "/recap"

    # read in our 'last-ingest-file' file - or abort if not found.
    # this file tells us the last file that was ingested.
    last_ingest_file = extract_dir + '/last-ingest.txt'
    raise "Can't find last-ingest-file #{last_ingest_file}" unless File.exist?(last_ingest_file)
    Rails.logger.info("--- found last_ingest_file: #{last_ingest_file}")

    last_ingest = File.read(last_ingest_file).strip
    raise "Cannot find last-ingest in last-ingest-file #{last_ingest_file}" if last_ingest.blank?
    Rails.logger.info("--- last ingest: #{last_ingest}")
    
    # retrieve the list of files, sorted (alphanumeric sort == chronological sort)
    all_files = Dir.glob("#{extract_dir}/PUL-NYPL*.zip").map { |f| File.basename(f)}.sort
    raise "Can't find any ingest files in #{extract_dir}" if all_files.size == 0
    Rails.logger.info("--- found #{all_files.size} total files.")
    # puts all_files.inspect
    
    # identify files that came after the last-ingest-file
    new_files = all_files.select { |file| file > last_ingest }
    Rails.logger.info("--- found #{new_files.size} new files since last ingest.")

    if new_files.size == 0
      Rails.logger.info("- No new files to ingest!  (Did you run 'recap:download' first?).")
      exit
    end
    
    if count != new_files.size
      Rails.logger.warn("--- warning: requested ingest of #{count} files, but #{new_files.size} new files found.")
    end
    
    # For each file in the list, ingest it.
    files_to_ingest = new_files[0,count]
    files_to_ingest.each do |filename|
      Rails.logger.info("--- Rake::Task[recap:ingest].invoke(#{filename})")
      Rake::Task["recap:ingest"].invoke(filename)
    end

    # Voila.  Now, record what we've done by writing out the last-ingested filename
    File.open(last_ingest_file, 'w') do |f|
      f.puts(files_to_ingest.last)
    end

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
  #     sftp = get_sftp()
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


def get_sftp()
  sftp_host = APP_CONFIG['recap']['sftp_host']
  sftp_user = APP_CONFIG['recap']['sftp_user']
  sftp_port = APP_CONFIG['recap']['sftp_port']
  sftp_keyfile = APP_CONFIG['recap']['sftp_keyfile']

  Rails.logger.info("--- opening SFTP connection to #{sftp_user}@#{sftp_host}:#{sftp_port}")
  sftp  = Net::SFTP.start(sftp_host, sftp_user, port: sftp_port, keys: [sftp_keyfile] )  
  raise "get_sftp() failed!" unless sftp

  return sftp  
end