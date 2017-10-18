

namespace :bibliographic do

  namespace :extract do

    # Used to test logging
    # task :noisy do
    #   Rails.logger.debug "noisy debug"
    #   Rails.logger.info "noisy info"
    #   Rails.logger.error "noisy error"
    # end

    desc "fetch the latest bibliographic extract from EXTRACT_HOME"
    task :fetch  do
      setup_ingest_logger
      extract = EXTRACTS.find { |x| x == ENV["EXTRACT"] }
      unless extract
        Rails.logger.error("Extract not specified")
        raise
      end
      extract_dir = APP_CONFIG['extract_home'] + "/" + extract

      temp_dir_name = File.join(Rails.root, "tmp/extracts/#{extract}/current/")
      temp_old_dir_name = File.join(Rails.root, "tmp/extracts/#{extract}/old/")

      FileUtils.rm_rf(temp_old_dir_name)
      FileUtils.mv(temp_dir_name, temp_old_dir_name) if File.exists?(temp_dir_name)
      FileUtils.mkdir_p(temp_dir_name)
      cp_command = "/bin/cp #{extract_dir}/* " + temp_dir_name
      Rails.logger.info("Fetching from #{extract_dir}")
      # puts cp_command
      if system(cp_command)
        Rails.logger.info("Fetch successful.")
      else
        Rails.logger.error("Fetch unsucessful")
        raise "Fetch unsucessful"
      end

      # # We don't expect .gz files, but if found, unzip them.
      # if system("gunzip -q " + temp_dir_name + "*.gz")
      #   Rails.logger.info("Gunzip successful")
      # end

    end


    desc "process deletes file"
    task :deletes => :environment do
      setup_ingest_logger
      extract = EXTRACTS.find { |x| x == ENV["EXTRACT"] }
      extract_files = Dir.glob(File.join(Rails.root, "tmp/extracts/#{extract}/current/*delete*")) if extract
      files_to_read = (ENV["DELETES_FILE"] || extract_files).listify.sort

      Rails.logger.info("No delete files found.") if files_to_read.empty?

      files_to_read.each do |file|
        raise "File does not exist: #{file}" unless File.exists?(file)

        Rails.logger.info("Processing file: #{file}")
        ids_to_delete = []

        File.open(file, "r").each do |line|
          ids_to_delete << line
        end

        ids_to_delete.sort.uniq!

        Rails.logger.info(ids_to_delete.length.to_s + " ids to delete.")
        begin
          solr_delete_ids(ids_to_delete)
          Rails.logger.info(ids_to_delete.length.to_s + " ids deleted (if in index)")
        rescue => e
          Rails.logger.error("Error during delete: " + e.inspect)
          raise e
        end

      end
    end


    desc "ingest latest bibliographic records"
    task :ingest => :environment do
      setup_ingest_logger
      extract = EXTRACTS.find { |x| x == ENV["EXTRACT"] }
      extract_files = Dir.glob(File.join(Rails.root, "tmp/extracts/#{extract}/current/*.{mrc,xml}")) if extract
      files_to_read = (ENV["INGEST_FILE"] || extract_files).listify.sort

      # create new traject indexer
      indexer = Traject::Indexer.new

      # explicity set the settings
      indexer.settings do
         provide "solr.url", Blacklight.connection_config[:url]
         provide 'debug_ascii_progress', true
         # 'debug' to echo full options
         provide 'log.level', 'info'
         # match our default application log format
         provide 'log.format', [ '%d [%L] %m', '%Y-%m-%d %H:%M:%S' ]
         provide 'processing_thread_pool', '0'
         provide "solr_writer.commit_on_close", 'true'
         # How many records skipped due to errors before we 
         #   bail out with a fatal error?
         provide "solr_writer.max_skipped", "100"
         # 10 x default batch sizes, sees some gains
         provide "solr_writer.batch_size", "1000"

         if ENV["DEBUG"]
           Rails.logger.info("- DEBUG set, writing to stdout")
           provide "writer_class_name", "Traject::DebugWriter"
         end
      end

      # load Traject config file (indexing rules)
      indexer.load_config_file(File.join(Rails.root, "config/traject/bibliographic.rb"))

      Rails.logger.info("- processing #{files_to_read.size} files...")

      # index each file 
      files_to_read.each do |filename|
        begin
          Rails.logger.info("--- processing #{filename}...")

          # Nokogiri XML parser can't handle illegal control chars
          if filename.ends_with?('.xml')
            Rails.logger.debug("----- cleaning #{filename}...")
            clean_ingest_file(filename)
          end

          File.open(filename) do |file|
            case File.extname(file)
            when '.mrc'
              indexer.settings['marc_source.type'] = 'binary'
            when '.xml'
              indexer.settings['marc_source.type'] = 'xml'
            end

            Rails.logger.debug("----- indexing #{filename}...")
            indexer.process(file)
          end
          Rails.logger.info("--- finished #{filename}.")
        rescue => e
          Rails.logger.error("Error during indexing (#{filename}): " + e.inspect)
          # don't raise, so rake can continue processing other files
          # raise e
        end
      end

      Rails.logger.info("- finished processing #{files_to_read.size} files.")

    end

    desc "download and ingest latest files"
    task :process => :environment do
      setup_ingest_logger
      Rake::Task["bibliographic:extract:fetch"].execute
      Rails.logger.info("Downloading successful.")

      Rake::Task["bibliographic:extract:deletes"].execute
      Rails.logger.info("Deletes successful.")

      Rake::Task["bibliographic:extract:ingest"].execute
      Rails.logger.info("Ingest successful.")


    end
  end


end



