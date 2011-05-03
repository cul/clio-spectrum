namespace :solr do
  namespace :ingest do
    desc "download the latest extract from taft.cul"
    task :download  do
      temp_dir_name = File.join(Rails.root, "tmp/extracts/current/")
      temp_old_dir_name = File.join(Rails.root, "tmp/extracts/old/")
      FileUtils.rm_rf(temp_old_dir_name)
      FileUtils.mv(temp_dir_name, temp_old_dir_name) if File.exists?(temp_dir_name)
      FileUtils.mkdir_p(temp_dir_name)
      if system("scp deployer@taft.cul.columbia.edu:/opt/dumps/newbooks* " + temp_dir_name)
        puts_and_log("Download successful.", :info)
      else
        puts_and_log("Download unsucessful", :error, :alarm => true)
      end


      if  system("gunzip " + temp_dir_name + "newbooks.mrc.gz")
        puts_and_log("Gunzip successful", :info)
      else
        puts_and_log("Gunzip unsuccessful", :error, :alarm => true)
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


    desc "process deletes file"
    task :deletes => :environment do
      deletes_file = ENV["DELETES_FILE"] || File.join(Rails.root, "tmp", "extracts", "current", "newbooks.deletes")

      if File.exists?(deletes_file)
        puts_and_log(deletes_file + " found.", :debug)
      else
        puts_and_log(deletes_file + " does not exist.", :error, :alarm => true)
      end


      ids_to_delete = []

      File.open(deletes_file, "r").each do |line|
        ids_to_delete << line
      end

      ids_to_delete.uniq!

      puts_and_log(ids_to_delete.length.to_s + " ids to delete.", :info)
      begin
        solr_delete_ids(ids_to_delete)
        puts_and_log(ids_to_delete.length.to_s + " ids deleted (if in index)", :info)
      rescue Exception => e
        puts_and_log("delete error: " + e.inspect, :error, :alarm => true)
      end
    end
  end


  desc "download and ingest latest newbooks file" 
  task :ingest => :environment do
      Rake::Task["solr:ingest:download"].execute
      puts_and_log("Downloading successful.")

      Rake::Task["solr:ingest:deletes"].execute
      puts_and_log("Deletes successful.")
    
    marc_file = "tmp/extracts/current/newbooks.mrc"
    ENV["MARC_FILE"] = marc_file

    begin
      Rake::Task["solr:marc:index"].reenable
      Rake::Task["solr:marc:index"].invoke
      puts_and_log ("Indexing succesful.")
    rescue Exception => e
      puts_and_log("Indexing  task failed to " + e.message, :error, :alarm => true)
      raise "Terminating due to failed ingest task."
    end

  end


end

def puts_and_log(msg, level = :info, params = {})
  full_msg = level.to_s + ": " + msg.to_s
  puts full_msg
  unless @logger 
    @logger = Logger.new(File.join(Rails.root, "log", "#{RAILS_ENV}_ingest.log"))
    @logger.formatter = Logger::Formatter.new
  end

  if defined?(RAILS_DEFAULT_LOGGER)
    RAILS_DEFAULT_LOGGER.send(level, msg)
  end

  @logger.send(level, msg)

  if params[:alarm]
    if ENV["EMAIL_ON_ERROR"] == "TRUE"
      IngestErrorNotifier.deliver_generic_error(:error => full_msg)
    end
    raise full_msg
  end

end

def solr_delete_ids(ids)
  retries = 5
  begin
    ids = ids.listify
    puts_and_log(ids.length.to_s + " deleting", :debug)
    Blacklight.solr.delete_by_id(ids)
    
    puts_and_log("Committing changes", :debug)
    Blacklight.solr.commit
    
    puts_and_log("Optimizing index", :debug)
    Blacklight.solr.optimize
  rescue Timeout::Error
    puts_and_log("Timed out!", :info)
    if retries <= 0
      puts_and_log("Out of retries, stopping delete process.", :error, :alarm => true)
    end

    puts_and_log("Trying again.", :info)
    retries -= 1
    retry
  end
end
