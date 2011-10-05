namespace :solr do
  desc "clear out solr for a date span"
  task :clear => :environment do
    start = ENV["START_TIME"] || "*"
    stop = ENV["STOP_TIME"] || "NOW"
    ids = solr_find_ids_by_timespan(start, stop) 

    if ENV["DRY_RUN"]
      puts_and_log "DRY RUN: #{ids.length} found from #{start} TO #{stop} would have been deleted"
    else
      solr_delete_ids(ids)
      puts_and_log "#{ids.length} found from #{start} TO #{stop} deleted"
    end
  end

  namespace :extract do

    desc "download the latest extract from taft.cul"
    task :download  do
      extract = ["new_arrivals", "spectrum", "databases"].find { |x| x == ENV["EXTRACT"] }
      puts_and_log("Extract not specified", :error, :alarm => true) unless extract

      temp_dir_name = File.join(Rails.root, "tmp/extracts/#{extract}/current/")
      temp_old_dir_name = File.join(Rails.root, "tmp/extracts/#{extract}/old/")

      FileUtils.rm_rf(temp_old_dir_name)
      FileUtils.mv(temp_dir_name, temp_old_dir_name) if File.exists?(temp_dir_name)
      FileUtils.mkdir_p(temp_dir_name)
      if system("scp deployer@taft.cul.columbia.edu:/opt/dumps/#{extract}/* " + temp_dir_name)
        puts_and_log("Download successful.", :info)
      else
        puts_and_log("Download unsucessful", :error, :alarm => true)
      end


      if  system("gunzip " + temp_dir_name + "*.mrc.gz")
        puts_and_log("Gunzip successful", :info)
      else
        puts_and_log("Gunzip unsuccessful", :error, :alarm => true)
      end  

    end




    desc "process deletes file"
    task :deletes => :environment do
      extract = ["new_arrivals", "spectrum","databases"].find { |x| x == ENV["EXTRACT"] }
      extract_files = Dir.glob(File.join(Rails.root, "tmp/extracts/#{extract}/current/*.deletes")) if extract
      files_to_read = (ENV["DELETES_FILE"] || extract_files).listify

      puts_and_log("No delete files found.", :info) if files_to_read.empty?

      files_to_read.each do |file|
        if File.exists?(file)
          puts_and_log("Processing file: #{file}", :info)
          ids_to_delete = []

          File.open(file, "r").each do |line|
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

        else
          puts_and_log("File does not exist: #{file}", :error)
        end
      end
    end

    desc "ingest latest marc records"
    task :ingest => :environment do
      extract = ["new_arrivals", "spectrum","databases"].find { |x| x == ENV["EXTRACT"] }
      extract_files = Dir.glob(File.join(Rails.root, "tmp/extracts/#{extract}/current/*.mrc")) if extract
      files_to_read = (ENV["INGEST_FILE"] || extract_files).listify

      files_to_read.each do |file|
        puts_and_log("Starting ingest of file: #{file}")
        begin
          ENV["MARC_FILE"] = file
          Rake::Task["solr:marc:index:work"].reenable
          Rake::Task["solr:marc:index:work"].invoke
          puts_and_log ("Indexing succesful.")
        rescue Exception => e
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

def solr_find_ids_by_timespan(start, stop)
  response = Blacklight.solr.find(:fl => "id", :filters => {:timestamp => "[" + start + " TO " + stop+"]"}, :per_page => 100000000)["response"]["docs"].collect(&:id).flatten
end


def puts_and_log(msg, level = :info, params = {})
  full_msg = level.to_s + ": " + msg.to_s
  puts full_msg
  unless @logger 
    @logger = Logger.new(File.join(Rails.root, "log", "#{Rails.env}_ingest.log"))
    @logger.formatter = Logger::Formatter.new
  end

  if defined?(Rails) && Rails.logger
    Rails.logger.send(level, msg)
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
