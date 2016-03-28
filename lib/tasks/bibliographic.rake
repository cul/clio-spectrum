


namespace :bibliographic do

  namespace :extract do

    desc "download the latest extract from EXTRACT_SCP_SOURCE"
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


    desc "ingest latest authority records"
    task :ingest => :environment do
      extract = EXTRACTS.find { |x| x == ENV["EXTRACT"] }
      extract_files = Dir.glob(File.join(Rails.root, "tmp/extracts/#{extract}/current/*.mrc")) if extract
      files_to_read = (ENV["INGEST_FILE"] || extract_files).listify

      # create new traject indexer
      indexer = Traject::Indexer.new

      # explicity set the settings
      indexer.settings do
         provide "solr.url", Blacklight.connection_config[:url]
         provide 'debug_ascii_progress', true
         provide "log.level", 'debug'
         provide 'processing_thread_pool', '0'
      end

      # load Traject config file (indexing rules)
      indexer.load_config_file(File.join(Rails.root, "config/traject/bibliographic.rb"))

      # index each file 
      files_to_read.each do |filename|
        File.open(filename) do |file|
          indexer.process(file)
        end
      end
    end

    desc "download and ingest latest files"
    task :process => :environment do
      Rake::Task["solr:extract:download"].execute
      puts_and_log("Downloading successful.")

      Rake::Task["solr:extract:deletes"].execute
      puts_and_log("Deletes successful.")

      Rake::Task["solr:extract:ingest"].execute
      puts_and_log("Ingest successful.")


    end
  end


end



