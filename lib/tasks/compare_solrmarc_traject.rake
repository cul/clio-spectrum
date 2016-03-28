


namespace :compare do

  desc "download the latest extract from extract_scp_source"
  task :download  do
    extract = EXTRACTS.find { |x| x == ENV["EXTRACT"] }
    puts_and_log("Extract not specified", :error, :alarm => true) unless extract

    temp_dir_name = File.join(Rails.root, "tmp/extracts/#{extract}/current/")
    temp_old_dir_name = File.join(Rails.root, "tmp/extracts/#{extract}/old/")

    FileUtils.rm_rf(temp_old_dir_name)
    FileUtils.mv(temp_dir_name, temp_old_dir_name) if File.exists?(temp_dir_name)
    FileUtils.mkdir_p(temp_dir_name)
    scp_command = "scp #{EXTRACT_SCP_SOURCE}/#{extract}/* " + temp_dir_name
    puts scp_command
    if system(scp_command)
      puts_and_log("Download successful.", :info)
    else
      puts_and_log("Download unsucessful", :error, :alarm => true)
    end

    if  system("gunzip " + temp_dir_name + "*.gz")
      puts_and_log("Gunzip successful", :info)
    else
      puts_and_log("Gunzip unsuccessful", :error, :alarm => true)
    end

  end


  desc "Process via Traject"
  task :traject => :environment do
    extract = EXTRACTS.find { |x| x == ENV["EXTRACT"] }
    extract_files = Dir.glob(File.join(Rails.root, "tmp/extracts/#{extract}/current/*.mrc")) if extract
    files_to_read = (ENV["INGEST_FILE"] || extract_files).listify

    output_file = File.join(Rails.root, "tmp/traject.out")

    puts_and_log("Indexing #{files_to_read} to #{output_file}")

    # create new traject indexer
    indexer = Traject::Indexer.new

    # explicity set the settings
    indexer.settings do
       provide 'debug_ascii_progress', true
       provide "log.level", 'debug'
       provide 'writer_class_name', 'DebugWriter'
       # format the Traject output to match SolrMarc debug output
       provide 'debug_writer.format', '%s : %s = %s'
       provide 'output_file', output_file
    end

    # load authorities config file (indexing rules)
    indexer.load_config_file(File.join(Rails.root, "config/traject/bibliographic.rb"))

    # index each file 
    files_to_read.each do |filename|
      File.open(filename) do |file|
        indexer.process(file)
      end
    end

  end

  desc "Process via SolrMarc"
  task :solrmarc => :environment do
    extract = EXTRACTS.find { |x| x == ENV["EXTRACT"] }
    extract_files = Dir.glob(File.join(Rails.root, "tmp/extracts/#{extract}/current/*.mrc")) if extract
    files_to_read = (ENV["INGEST_FILE"] || extract_files).listify



# lib/scripts/indextest.sh  tmp/extracts/incremental/current/updates.mrc  config/SolrMarc/config.properties

    indexer = File.join(Rails.root, "lib/scripts/indextest.sh")
    config = File.join(Rails.root, "config/SolrMarc/config.properties")
    output_file = File.join(Rails.root, "tmp/solrmarc.out")

    puts_and_log("Indexing #{files_to_read} to #{output_file}")

    # index each file 
    files_to_read.each do |filename|
      cmd = "#{indexer} #{filename} #{config} > #{output_file}"
      `#{cmd}`
    end

  end

  desc "download and compare latest files"
  task :process => :environment do
    Rake::Task["compare:download"].execute
    puts_and_log("Downloading successful.")

    Rake::Task["compare:solrmarc"].execute
    puts_and_log("SolrMarc index successful.")

    Rake::Task["compare:traject"].execute
    puts_and_log("Traject index successful.")

    Rake::Task["compare:diff"].execute
    puts_and_log("Diff SolrMarc v.s. Traject complete.")

  end

end





