

namespace :authorities do

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
      scp_command = "scp #{extract_scp_source}/#{extract}/* " + temp_dir_name
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
      extract = extracts.find { |x| x == ENV["EXTRACT"] }
      extract_files = Dir.glob(File.join(Rails.root, "tmp/extracts/#{extract}/current/*.mrc")) if extract
      files_to_read = (ENV["INGEST_FILE"] || extract_files).listify

      # create new traject indexer
      indexer = Traject::Indexer.new

      # explicity set the settings
      indexer.settings do
         provide "solr.url", APP_CONFIG['authorities_solr']
         provide 'debug_ascii_progress', true
         provide "log.level", 'debug'
      end

      # load authorities config file (indexing rules)
      indexer.load_config_file(File.join(Rails.root, "config/traject/authorities.rb"))

      # index each file 
      files_to_read.each do |filename|
        File.open(filename) do |file|
          indexer.process(file)
        end
      end
    end


    desc "download and ingest latest authority files"
    task :process => :environment do
      Rake::Task["authorities:extract:download"].execute
      puts_and_log("Downloading successful.")

      Rake::Task["authorities:extract:ingest"].execute
      puts_and_log("Ingest successful.")
    end

  end

end



