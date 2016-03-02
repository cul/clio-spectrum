
require File.join(Rails.root.to_s, 'config', 'initializers/aaa_load_app_config.rb')

EXTRACT_SCP_SOURCE = APP_CONFIG['extract_scp_source']

EXTRACTS =  ["full", "incremental", "cumulative", "subset", "law", "test"]


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


    desc "ingest latest marc records"
    task :ingest => :environment do
      extract = EXTRACTS.find { |x| x == ENV["EXTRACT"] }
      extract_files = Dir.glob(File.join(Rails.root, "tmp/extracts/#{extract}/current/*.mrc")) if extract
      files_to_read = (ENV["INGEST_FILE"] || extract_files).listify

      files_to_read.each do |file|
        puts_and_log("Starting ingest of file: #{file}")
        begin
          ENV["MARC_FILE"] = file
          Rake::Task["solr:marc:index:work"].reenable
          Rake::Task["solr:marc:index:work"].invoke
# Rake::Task["solr:marc:index:info"].invoke
          puts_and_log ("Indexing succesful.")
        rescue => e
          puts_and_log("Indexing  task failed to " + e.message, :error, :alarm => true)
          raise "Terminating due to failed ingest task."
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



