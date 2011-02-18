namespace :solr do
  namespace :ingest do
    desc "download the latest extract from taft.cul"
    task :download  do
      temp_dir_name = "tmp/extracts/raw"
      FileUtils.rm_rf(temp_dir_name)
      FileUtils.mkdir_p(temp_dir_name)

      timecode = DateTime.now.strftime("%y%m%d%H%M%S")
      final_dir_name = "tmp/extracts/" + timecode 
      if system("scp deployer@taft.cul.columbia.edu:/opt/dumps/newbooks* " + temp_dir_name + "/")
        puts_and_log("Download successful.", :debug)
      else
        puts_and_log("Download unsucessful")
        raise "Download unsuccessful."
      end

      
      raise "gunzip unsuccessful" unless  system("gunzip " + temp_dir_name + "/newbooks.mrc.gz")
        
        
      FileUtils.rm_f(temp_dir_name + "/*.gz")
      FileUtils.mv(temp_dir_name , final_dir_name)
      FileUtils.ln_s(timecode, "tmp/extracts/latest", :force => true)
    end

    namespace :download do
      desc "cleanup all but last 3 extracts" 
      task :cleanup do
        to_keep = ENV["keep_extracts"] || 3
        directories = Dir.entries("tmp/extracts").reject { |c| c =~ /^\D/}.collect { |d| "tmp/extracts/" + d}.sort_by { |d| File.stat(d).ctime }
        
        directories_to_remove = directories[0, [directories.length-3,0].max]
      
        puts_and_log(directories_to_remove.length.to_s + " directories to remove")

        directories_to_remove.each { |dir| FileUtils.rm_rf(dir) }
      end
    end

    namespace :clear do 

      desc "clear out solr for a date span"
      task :timespan => :environment do
        start = ENV["START_TIME"] || raise("Must specify START_TIME")
        stop = ENV["STOP_TIME"] || "NOW"

        ids = solr_find_ids_by_timespan(start, stop) 

        if ENV["DRY_RUN"]
          puts_and_log "DRY RUN: #{ids.length} found from #{start} TO #{stop} would have been deleted"
        else
          solr_delete_ids(ids)
          puts_and_log "#{ids.length} found from #{start} TO #{stop} deleted"
        end
      end
    end

    
  end


  desc "download and ingest latest newbooks file" 
  task :ingest => :environment do
    env = ENV["RAILS_ENV"] || "development" 
    config_file = "config/SolrMarc/config-#{env}.properties"

    if ENV["SKIP_CONFIG_CHECK"]
      puts_and_log("skipping config check")
    elsif File.exists?(config_file)
      puts_and_log("found config file" + config_file)
    else
      puts_and_log("Did not find config file " + config_file)
      raise ("Terminating due to missing config file.")
    end


    time_start = Time.now

    begin
      Rake::Task["solr:ingest:download"].execute
      puts_and_log("Downloading successful.")
    rescue Exception => e
      puts_and_log("Download task failed to " + e.message)
      raise "Terminating due to failed download task."
    end

    marc_file = "tmp/extracts/latest/newbooks.mrc"
    ENV["MARC_FILE"] = marc_file
    
    begin
      Rake::Task["solr:marc:index"].reenable
      Rake::Task["solr:marc:index"].invoke
      puts_and_log ("Indexing succesful.")
    rescue Exception => e
      puts_and_log("Indexing  task failed to " + e.message)
      raise "Terminating due to failed ingest task."
    end

    ids_to_delete = solr_find_ids_by_timespan("*", time_start.utc.iso8601)
    puts_and_log(ids_to_delete.length.to_s + " ids to delete")
    solr_delete_ids(ids_to_delete) unless ids_to_delete.empty?
  
  
    begin
      Rake::Task["solr:ingest:download:cleanup"].reenable
      Rake::Task["solr:ingest:download:cleanup"].invoke
      puts_and_log ("Cleanup succesful.")
    rescue Exception => e
      puts_and_log("Cleanup  task failed to " + e.message)
      raise "Terminating due to failed cleanup task."
    end
  
  end


end

def puts_and_log(msg, level = :info)
  puts level.to_s + ": " + msg.to_s
  if defined?(RAILS_DEFAULT_LOGGER)
    RAILS_DEFAULT_LOGGER.send(level, msg)
  end

end

def solr_find_ids_by_timespan(start, stop)
  Blacklight.solr.find(:fl => "id", :filters => {:timestamp => "[" + start + " TO " + stop+"]"}, :per_page => 100000000)["response"]["docs"].collect(&:id)
end

def solr_delete_ids(ids)
  Blacklight.solr.delete_by_id(ids)
  Blacklight.solr.commit
  Blacklight.solr.optimize
end
