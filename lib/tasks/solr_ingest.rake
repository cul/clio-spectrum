namespace :solr do
  namespace :ingest do
    desc "download the latest extract from taft.cul"
    task :download  do
      temp_dir_name = "tmp/extracts/raw"
      FileUtils.rm_rf(temp_dir_name)
      FileUtils.mkdir_p(temp_dir_name)

      timecode = DateTime.now.strftime("%y%m%d%H%M%S")
      final_dir_name = "tmp/extracts/" + timecode 
      system("scp deployer@taft.cul.columbia.edu:/opt/dumps/newbooks* " + temp_dir_name + "/")

      system("gunzip " + temp_dir_name + "/newbooks.mrc.gz")
      FileUtils.rm_f(temp_dir_name + "/*.gz")
      FileUtils.mv(temp_dir_name , final_dir_name)
      FileUtils.ln_s(timecode, "tmp/extracts/latest", :force => true)
    end

    namespace :download do
      desc "clear all downloads but latest"
      # task :clear do

      # end
    end

    namespace :clear do 

      desc "clear out solr for a date span"
      task :timespan => :environment do
        start = ENV["START_TIME"] || raise("Must specify START_TIME")
        stop = ENV["STOP_TIME"] || "NOW"

        ids = solr_find_ids_by_timespan(start, stop) 
        puts "#{ids.length} found from #{start} TO #{stop}"

        unless ENV["DRY_RUN"]
          solr_delete_ids(ids)
          puts "and deleted"
        end
      end
    end

    
  end

  desc "download and ingest latest newbooks file" 
  task :ingest => :environment do
    time_start = Time.now
    Rake::Task["solr:ingest:download"].execute
    marc_file = "tmp/extracts/latest/newbooks.mrc"

    Rake::Task["solr:marc:index"].reenable
    ENV["MARC_FILE"] = marc_file
    Rake::Task["solr:marc:index"].invoke

    ids_to_delete = solr_find_ids_by_timespan("*", time_start.utc.iso8601)
    puts ids_to_delete.length.to_s + " ids to delete"
    # solr_delete_ids(ids_to_delete)
  end


end

def log_and_put(msg, level = :info)
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
