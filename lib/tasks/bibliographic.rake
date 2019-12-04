

namespace :bibliographic do

  desc 'Invoke a set of other rake tasks, to be executed daily'
  task daily: :environment do
    startTime = Time.now
    puts_datestamp '====>>>  START bibliographic:daily  <<<===='

    puts_datestamp '==== bibliographic:extract:fetch (full) ===='
    ENV['EXTRACT'] = 'full'
    Rake::Task['bibliographic:extract:fetch'].invoke
    Rake::Task['bibliographic:extract:fetch'].reenable

    puts_datestamp '==== bibliographic:extract:ingest_full_slice ===='
    Rake::Task['bibliographic:extract:ingest_full_slice'].invoke

    puts_datestamp '==== bibliographic:extract:process (cumulative) ===='
    ENV['EXTRACT'] = 'cumulative'
    Rake::Task['bibliographic:extract:process'].invoke

    puts_datestamp '==== bibliographic:extract:process (incremental) ===='
    ENV['EXTRACT'] = 'incremental'
    Rake::Task['bibliographic:extract:process'].invoke

    puts_datestamp '==== bibliographic:prune_index ===='
    Rake::Task['bibliographic:prune_index'].invoke

    # Skip the optimize, rely on segment merging
    # puts_datestamp '---- bibliographic:optimize ----'
    # Rake::Task['bibliographic:optimize'].invoke

    elapsed_minutes = (Time.now - startTime).div(60).round
    hrs, min = elapsed_minutes.divmod(60)
    elapsed_note = "(#{hrs} hrs, #{min} min)"
    puts_datestamp "====>>>  END bibliographic:daily #{elapsed_note}  <<<===="
  end

  desc 'delete stale records from the solr index'
  task prune_index: :environment do
    setup_ingest_logger
    Rails.logger.info('-- pruning index...')

    solr_url = Blacklight.connection_config[:indexing_url] ||
               Blacklight.connection_config[:url]
    solr_connection = RSolr.connect(url: solr_url)
    # puts "solr_connection=#{solr_connection}" if ENV['DEBUG']

    if ENV['STALE_DAYS'] && ENV['STALE_DAYS'].to_i < 30
      puts "ERROR: Environment variable STALE_DAYS set to [#{ENV['STALE_DAYS']}]"
      puts 'ERROR: Should be > 30, or unset to allow default setting.'
      puts 'ERROR: Skipping prune_index step.'
      next
    end
    stale = (ENV['STALE_DAYS'] || 70).to_i
    Rails.logger.info("-- pruning records older than [ #{stale} ] days.")
    # TODO: - SOLR RECORDS SHOULD SELF-IDENTIFY AS VOYAGER FEED RECORDS
    query = "timestamp:[* TO NOW/DAY-#{stale}DAYS] AND id:[0 TO 999999]"
    puts "DEBUG query=#{query}" if ENV['DEBUG']

    # To be safe, refuse to delete over N records
    response = solr_connection.get 'select', params: { q: query, rows: 0 }
    numFound = response['response']['numFound'].to_i

    Rails.logger.info("-- found #{numFound} stale records.")

    prune_limit = (ENV['PRUNE_LIMIT'] || 10000).to_i
    if numFound > prune_limit
      message = "ERROR:  prune limit set to #{prune_limit}, found [#{numFound}] stale records - skipping!"
      Rails.logger.error("-- #{message}")
      puts message
    else
      if numFound > 0
        Rails.logger.info('-- pruning...')
        solr_connection.delete_by_query query
        solr_connection.commit
      end
    end

    # Oh wait - we need to prune Law too (bib keys look like: b\d+)
    # Just delete, don't be so worried about mistakes.  All Law bibs
    # get automatically reloaded weekly anyway.
    Rails.logger.info('-- pruning law...')
    query = "timestamp:[* TO NOW/DAY-#{stale}DAYS] AND id:[b0 TO b999999]"
    solr_connection.delete_by_query query
    solr_connection.commit

    Rails.logger.info('-- pruning complete.')
  end

  desc 'optimize the solr index'
  task optimize: :environment do
    Rails.logger.info('-- requesting optimize...')

    begin
      solr_url = Blacklight.connection_config[:indexing_url] ||
                 Blacklight.connection_config[:url]
      solr_connection = RSolr.connect(url: solr_url)
      solr_connection.optimize
    rescue Faraday::TimeoutError, Net::ReadTimeout
      # Do nothing - we expect our client call to timeout
      # while the server does an optimize of a 50GB+ index.
    end
    # We kicked it off, but can't tell if it's going to work or not.
    Rails.logger.info('-- optimize requested.')
  end

  namespace :extract do
    # Used to test logging
    # task :noisy do
    #   Rails.logger.debug "noisy debug"
    #   Rails.logger.info "noisy info"
    #   Rails.logger.error "noisy error"
    # end

    desc 'fetch the latest bibliographic extract from EXTRACT_HOME'
    task :fetch do
      setup_ingest_logger
      extract = EXTRACTS.find { |x| x == ENV['EXTRACT'] }
      unless extract
        Rails.logger.error('Extract not specified -- aborting')
        abort
      end
      extract_dir = APP_CONFIG['extract_home'] + '/' + extract

      temp_dir_name = File.join(Rails.root, "tmp/extracts/#{extract}/current/")
      temp_old_dir_name = File.join(Rails.root, "tmp/extracts/#{extract}/old/")

      FileUtils.rm_rf(temp_old_dir_name)
      FileUtils.mv(temp_dir_name, temp_old_dir_name) if File.exist?(temp_dir_name)
      FileUtils.mkdir_p(temp_dir_name)
      cp_command = "/bin/cp #{extract_dir}/* " + temp_dir_name
      Rails.logger.info("Fetching from #{extract_dir}")
      Rails.logger.info("to #{temp_dir_name}")
      # puts cp_command
      if system(cp_command)
        Rails.logger.info('Fetch successful.')
      else
        Rails.logger.error('Fetch unsucessful')
        raise 'Fetch unsucessful'
      end

      # # We don't expect .gz files, but if found, unzip them.
      # if system("gunzip -q " + temp_dir_name + "*.gz")
      #   Rails.logger.info("Gunzip successful")
      # end
    end

    desc 'process deletes file'
    task deletes: :environment do
      setup_ingest_logger
      extract = EXTRACTS.find { |x| x == ENV['EXTRACT'] }
      extract_files = Dir.glob(File.join(Rails.root, "tmp/extracts/#{extract}/current/*delete*")) if extract
      files_to_read = (ENV['DELETES_FILE'] || extract_files).listify.sort

      Rails.logger.info('No delete files found.') if files_to_read.empty?

      files_to_read.each do |file|
        raise "File does not exist: #{file}" unless File.exist?(file)

        Rails.logger.info("Processing file: #{file}")
        ids_to_delete = []

        File.open(file, 'r').each do |line|
          ids_to_delete << line
        end

        ids_to_delete.sort.uniq!
        id_count = ids_to_delete.size

        Rails.logger.info("#{id_count} ids to delete.")
        Rails.logger.info("(deleting in slices of #{DELETES_SLICE} ids)") if id_count > DELETES_SLICE

        ids_to_delete.each_slice(DELETES_SLICE) do |slice|
          begin
            solr_url = Blacklight.connection_config[:indexing_url] || Blacklight.connection_config[:url]
            solr_connection = RSolr.connect(url: solr_url)
            solr_delete_ids(solr_connection, slice)
            Rails.logger.info("#{slice.size} ids deleted (if in index)")
          rescue => e
            Rails.logger.error('Error during delete: ' + e.inspect)
            raise e
          end
        end
      end
    end

    desc 'ingest latest bibliographic records'
    task ingest: :environment do
      setup_ingest_logger
      extract = EXTRACTS.find { |x| x == ENV['EXTRACT'] }
      Rails.logger.info("- begin task bibliographic:extract:ingest with extract=#{extract}")

      extract_files = Dir.glob(File.join(Rails.root, "tmp/extracts/#{extract}/current/*.xml")) if extract
      files_to_read = (ENV['INGEST_FILE'] || extract_files).listify.sort
      Rails.logger.info("- processing #{files_to_read.size} files...")

      # index each file
      files_to_read.each do |filename|
        # Rails.logger.info("- Rake::Task[bibliographic:extract:ingest_file].invoke(#{filename})")
        Rails.logger.info('-' * 60)
        Rake::Task['bibliographic:extract:ingest_file'].reenable
        Rake::Task['bibliographic:extract:ingest_file'].invoke(filename)
      end
      Rails.logger.info('-' * 60)

      Rails.logger.info("- finished processing #{files_to_read.size} files.")
    end

    desc 'ingest single specified MARC file'
    task :ingest_file, [:filename] => :environment do |_t, args|
      setup_ingest_logger
      Rails.logger.info('---- begin task bibliographic:extract:ingest_file')

      Rails.logger.debug('---- turning off http(s)_proxy (squid)')
      ENV.delete('http_proxy')
      ENV.delete('https_proxy')

      filename = args[:filename]
      abort('bibliographic:extract:ingest_file[:filename] not passed filename!') unless filename
      abort("bibliographic:extract:ingest_file[:filename] passed non-existant filename #{filename}") unless File.exist?(filename)
      abort('bibliographic:extract:ingest_file[:filename] not an XML file!') unless filename.ends_with?('.xml')
      Rails.logger.info("---- filename: #{filename}")

      # create new traject indexer
      indexer = Traject::Indexer.new

      # explicity set the settings
      indexer.settings do
        provide 'solr.url', Blacklight.connection_config[:indexing_url] || Blacklight.connection_config[:url]
        provide 'debug_ascii_progress', true
        # 'debug' to see full traject options
        provide 'log.level', 'info'
        # match our default application log format
        provide 'log.format', ['%d [%L] %m', '%Y-%m-%d %H:%M:%S']
        # thread pool boosts throughput, even on MRI
        provide 'processing_thread_pool', '10'
        provide 'solr_writer.commit_on_close', 'true'
        # How many records skipped due to errors before we
        #   bail out with a fatal error?
        provide 'solr_writer.max_skipped', '100'
        # 10 x default batch sizes, sees some gains
        provide 'solr_writer.batch_size', '1000'
        # 12/2017 - drop support for .mrc, only .xml henceforth
        provide 'marc_source.type', 'xml'

        if ENV['DEBUG']
          Rails.logger.info('---- *** DEBUG set, writing to stdout ***')
          provide 'writer_class_name', 'Traject::DebugWriter'
        end
      end

      # load Traject bibliographic config file (indexing rules)
      indexer.load_config_file(File.join(Rails.root, 'config/traject/bibliographic.rb'))

      begin
        # Nokogiri XML parser can't handle illegal control chars
        if filename.ends_with?('.xml')
          Rails.logger.debug("---- cleaning #{filename}...")
          clean_ingest_file(filename)
          Rails.logger.debug('---- XML well-formedness check...')
          if File.exist?('/usr/bin/xmlwf')
            # Rails.logger.debug("----- running xmllint against #{filename}...")
            # output, status = Open3.capture2e("xmllint --noout #{filename}")
            command = "xmlwf -r #{filename}"
            output, status = Open3.capture2e(command)
            # if status.nonzero?
            if ! status.success?
              Rails.logger.error('XML file failed well-formedness check -- aborting!')
              Rails.logger.error("command: #{command}")
              Rails.logger.error("output: #{output}")
              abort
            end
          else
            Rails.logger.debug('---- xmlwf not found - skipping well-formedness check!')
          end
        end

        Rails.logger.debug("---- indexing #{filename}...")
        File.open(filename) do |file|
          indexer.process(file)
        end
        Rails.logger.info("---- finished #{filename}.")
      rescue => e
        Rails.logger.error("Error during indexing (#{filename}): " + e.inspect)
        # don't raise, so rake can continue processing other files
        # raise e
      end
    end

    desc 'download and ingest latest files'
    task process: :environment do
      setup_ingest_logger
      Rake::Task['bibliographic:extract:fetch'].execute
      Rails.logger.info('Downloading successful.')

      Rake::Task['bibliographic:extract:deletes'].execute
      Rails.logger.info('Deletes successful.')

      Rake::Task['bibliographic:extract:ingest'].execute
      Rails.logger.info('Ingest successful.')
    end

    # Each day of the month (1-N), ingest some of the files from 'full',
    # so that within each month we'll have re-processed the complete 'full'.
    # There are about 130 full files currently.
    # If we do ten per night, we can cover all the files in half a month.
    desc "ingest a partial slice of the 'full' extract (run this every day)"
    task :ingest_full_slice, [:monthday] => :environment do |_t, args|
      setup_ingest_logger
      Rails.logger.info('- begin task bibliographic:extract:ingest_full_slice')

      full_dir = 'tmp/extracts/full/current'
      todays_slice_of_full = []

      # Create a range of ten files, based on day-of-the-month
      # E.g., on the 12th, we'll look for "111" through "120"
      monthday = Date.today.strftime('%d')
      if args[:monthday]
        Rails.logger.warn("- MONTHDAY OVERRIDE - was #{monthday}, override with #{args[:monthday]}")
        monthday = args[:monthday]
        unless monthday.match(/^\d+$/) && monthday.to_i > 0 && monthday.to_i < 32
          Rails.logger.error("- illegal monthday override value [#{monthday}] - aborting.")
          next
        end
      end
      Rails.logger.info("- Day of the Month is:  #{monthday}")
      slice_end = 10 * monthday.to_i
      slice_start = slice_end - 9
      Rails.logger.info("- indexing full extract files numbered #{slice_start} through #{slice_end}")
      (slice_start..slice_end).to_a.each do |counter|
        extract_file = sprintf('extract-%03d.xml', counter)
        filename = "#{full_dir}/#{extract_file}"
        todays_slice_of_full.push(filename) if File.exist?(filename)
      end
      Rails.logger.info("- processing #{todays_slice_of_full.size} extract files found within this range")
      # provide additional hints if they might be useful
      Rails.logger.info("- (within dir #{full_dir})") if todays_slice_of_full.size < 10

      next if todays_slice_of_full.size.zero?

      todays_slice_of_full.each do |filename|
        Rails.logger.info('-' * 60)
        Rake::Task['bibliographic:extract:ingest_file'].reenable
        Rake::Task['bibliographic:extract:ingest_file'].invoke(filename)
      end
      Rails.logger.info('-' * 60)

      Rails.logger.info("- finished processing #{todays_slice_of_full.size} files.")
    end

    # end 'extract'
  end

  # Just clean a file, not really in the context of
  # processing an extract.  Useful utility.
  desc 'Clean a single MARC XML file of invalid bytes'
  task :clean_file, [:filename] => :environment do |_t, args|
    # setup_ingest_logger
    filename = args[:filename]
    puts("- Cleaning #{filename}...")
    raise 'filename blank!' if filename.blank?
    raise "no such file '#{filename}'!" unless File.exist?(filename)
    clean_ingest_file(filename)
  end

  # end 'bibliographic'
end

def puts_datestamp(msg)
  puts "#{Time.now}   #{msg}"
end
