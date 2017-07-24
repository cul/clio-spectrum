
namespace :authorities do

  namespace :extract do

    desc "fetch the latest authorities extract from EXTRACT_HOME"
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
      # scp_command = "scp #{EXTRACT_SCP_SOURCE}/#{extract}/* " + temp_dir_name
      # puts scp_command
      # if system(scp_command)
      #   Rails.logger.info("Download successful.")
      # else
      #   puts_and_log("Download unsucessful", :error, alarm: true)
      # end

      # We don't expect .gz files, but if found, unzip them.
      if system("gunzip " + temp_dir_name + "*.gz")
        Rails.logger.info("Gunzip successful")
      end
    end

    desc "rewrite marc files to marcxml"
    task :to_xml do
      setup_ingest_logger

      extract = EXTRACTS.find { |x| x == ENV["EXTRACT"] }
      puts_and_log("Unknown extract: #{ENV['EXTRACT']}", :error) unless extract

      extract_files = Dir.glob(File.join(Rails.root, "tmp/extracts/#{extract}/current/*.mrc")) if extract
      files_to_read = (ENV["INGEST_FILE"] || extract_files).listify.sort
      puts "transforming #{files_to_read.size} files from MARC to MARCXML"

      xmldir = File.join(Rails.root, "tmp/extracts/#{extract}/xml")
      FileUtils.rm_rf(xmldir)
      FileUtils.mkdir_p(xmldir)

      files_to_read.each do |filename|
        puts "- transforming #{filename}..."
        xmlfile = File.join(xmldir, File.basename(filename, '.mrc') + ".xml")

        reader = MARC::Reader.new(filename)
        writer = MARC::XMLWriter.new(xmlfile)

        for record in reader
          writer.write(record)
        end

        writer.close()
      end
      puts "done."
    end

    desc "ingest latest authority records"
    task :ingest => :environment do
      setup_ingest_logger
      extract = EXTRACTS.find { |x| x == ENV["EXTRACT"] }
      puts_and_log("Unknown extract: #{ENV['EXTRACT']}", :error) unless extract

      extract_files = Dir.glob(File.join(Rails.root, "tmp/extracts/#{extract}/current/*.mrc")) if extract
      files_to_read = (ENV["INGEST_FILE"] || extract_files).listify.sort

      # create new traject indexer
      indexer = Traject::Indexer.new

      # explicity set the settings
      indexer.settings do
         provide "solr.url", APP_CONFIG['authorities_solr_url']
         provide 'debug_ascii_progress', true
         # 'debug' to see full traject options
         provide "log.level", 'info'
         # match our default application log format
         provide 'log.format', [ '%d [%L] %m', '%Y-%m-%d %H:%M:%S' ]
         provide "solr_writer.commit_on_close", "true"
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

      # load authorities config file (indexing rules)
      indexer.load_config_file(File.join(Rails.root, "config/traject/authorities.rb"))

      Rails.logger.info("- processing #{files_to_read.size} files...")

      # index each file 
      files_to_read.each do |filename|
        Rails.logger.info("--- processing #{filename}...")
        File.open(filename) do |file|
          Rails.logger.debug("----- indexing #{filename}...")
          indexer.process(file)
        end
        Rails.logger.info("--- finished #{filename}.")
      end
    end

    desc "download and ingest latest authority files"
    task :process => :environment do
      setup_ingest_logger
      Rake::Task["authorities:extract:download"].execute
      Rails.logger.info("Downloading successful.")

      Rake::Task["authorities:extract:ingest"].execute
      Rails.logger.info("Ingest successful.")
    end
  end

  namespace :add_to_bib do

    task :by_extract, [:extract, :age] do |t, args|
      setup_ingest_logger
      extract = args[:extract]
      raise "usage:  authorities:add_to_bib:by_extract[incremental]" unless extract

      biblist = []
      extract_files = Dir.glob(File.join(Rails.root, "tmp/extracts/#{extract}/current/*.{mrc,xml}"))
      Rails.logger.info("- processing #{extract_files.size} files...")
      extract_files.each do |filename|
        Rails.logger.info("-- processing #{filename}...")
        begin

          case File.extname(filename)
          when '.mrc'
            reader = MARC::Reader.new(filename)
            for record in reader
              biblist.push record['001'].value
            end
          when '.xml'
            # <controlfield tag="001">2</controlfield>
            open(filename) do |file|
              file.each_line do |line|
                if match = line.match(/<controlfield tag=.001.>(.*)<.controlfield>/i)
                  biblist.push match.captures.first
                  # puts match.captures.first
                end
              end
            end
          end

        rescue => e
          puts_and_log("MARC::Reader.new(#{filename}): " + e.inspect, :error)
        end
      end

      add_variants_to_biblist(biblist, args[:age])
    end

    task :by_range, [:start, :stop, :age] do |t, args|
      setup_ingest_logger
      raise "usage:  authorities:add_by_range[10000,11000]" unless args[:start] and args[:stop]
      biblist = ( args[:start] .. args[:stop] ).to_a

      add_variants_to_biblist(biblist, args[:age])
    end

    task :by_bibfile, [:bib_file, :age] do |t, args|
      setup_ingest_logger
      bibfile = args[:bib_file]
      # biblist = IO.readlines bibfile
      biblist = File.open(bibfile).readlines.map(&:strip)

      add_variants_to_biblist(biblist, args[:age])
    end

    desc "Get list of bib ids by running query against bib solr"
    task :by_query,  [:query, :age] do |t, args|
      setup_ingest_logger
      query = args[:query]
      raise "usage:  authorities:add_to_bib:by_query['Miocardial infarction']" unless query

      puts "querying bib solr for '#{query}'..."
      cutoff = 10000
      response = BIB_SOLR.get 'select', params: {q: query, fl: 'id', rows: cutoff}
      raise "Error querying Bib Solr!" unless
          response && response['response'] && response['response']['docs']

      hits = response['response']['docs'].size
      puts "found #{hits} bibs."
      puts "(** cutoff at #{cutoff} bibs)" if hits >= cutoff
      puts "No hits - giving up." if hits == 0
      next if hits < 1

      biblist = response['response']['docs'].map { |doc| doc['id'] }
      add_variants_to_biblist(biblist, args[:age])

    end
  end

end



#############################################
####   Batch processing approach below   ####
# Gets very messy fast - we'll come back to this
# work if we need to.
#############################################

# # Given a list of bib IDs, 
# # lookup Authority variants for Authors, Subject Topics
# # Skip records which have been processed in the last AGE days
# def add_variants_to_biblist_by_batch(biblist, age)
# 
#   save_biblist_for_debug(biblist)
# 
#   # Reduce # of Solr API calls by working with batches
#   batch_size = 10
#   biblist.in_groups_of(batch_size) do |batch|
# 
#     # Query the bibliographic Solr for authorized forms
#     authorized_forms = get_authorized_forms_for_batch(batch, age)
# 
#     # Query the authorities Solr for variant forms
#     author_variants = lookup_author_variants_for_batch(authorized_forms)
#     subject_variants = lookup_subject_variants_for_batch(authorized_forms)
# 
#     # Update the bibliographic Solr with variant forms
#     batch_update(authorized_forms, author_variants, subject_variants)
# 
#   end
# 
# end
# 
# 
# # input array of bib id integers, string days-since-last-lookup
# #   batch:   [101, 210, 363, nil]
# #   age:     "7"
# # return array of id/authorized-form 
# #   [ { id: 101, author_facet: 'Smith, Adam' }, 
# #     { id: 210, author_facet: 'Doe, John', subject_topic_facet: "Aliases" } ]
# def get_authorized_forms_for_batch(batch, age)
#   authorized_forms = []
# 
#   # [101, 210, 363, nil] ==> "id:101 OR id:210 OR id:363"
#   q = batch.select{|bib| bib.present?}.map{|bib| "id:#{bib}" }.join(" OR ")
# 
#   # fetch the authorizied forms from the bib
#   params = {q: q, facet: 'off', fl: 'author_facet,subject_topic_facet,authorities_dt'}
# 
#   response = BIB_SOLR.get 'select', params: params
# 
#   age = cleanup_age_param(age)
#   response["response"]["docs"].each { |doc|
#     # Only select docs in need of lookup - freshly looked up record are skipped
#     if doc['authorities_dt'] && ((DateTime.now - Date.parse(doc['authorities_dt'])).to_i < age)
#       puts "skipping bib record #{doc['id']} - looked up recently"
#       next
#     end
# 
#     # skip 
#     if doc[:author_facet].nil? and doc[:subject_topic_facet].nil?
#       puts "skipping bib record #{doc['id']} - no author/subject values"
#       next
#     end
# 
#     authorized_forms.push( doc.slice(:id, :author_facet, :subject_topic_facet) )
#   }
# 
# end
# 
# # input an array of authorized forms
# #   [ { id: 101, author_facet: 'Smith, Adam' }, 
# #     { id: 210, author_facet: 'Doe, John', subject_topic_facet: "Aliases" } ]
# # output a hash of authorized-to-variant forms
# #  { 'Smith, Adam' => ['Smitty', 'Adamicus'],
# #    'Doe, John',  => ['Mr. Nobody', 'anonymous', 'persona incognito'] }
# def lookup_author_variants_for_batch(authorized_forms)
#   params  = { bib_field: 'author_facet', auth_field: 'author_t', variant_field: 'author_variant_t'}
#   lookup_variants_for_batch(authorized_forms, params)
# end
# 
# 
# def lookup_variants_for_batch(authorized_forms, params)
#   variants = {}
# 
#   # transform bibliographic docs into a query string
#   # output string:  "'Smith, Adam' OR 'Doe, John'"
#   q = authorized_forms.select { |doc|
#     doc[ params[:bib_field] ].present?
#   }.map { |doc|
#     doc[ params[:bib_field] ].gsub(/"/, '\"')
#   }.join (" OR ")
# 
#   fl = "id,#{params[:auth_field]},#{params[:variant_field]}"
# 
#   variant_batch = queryasdfasdf_variants_for_batch(q, fl)
# 
#   # transform authorities docs into a form/variant-list hash
#   variant_batch.each { |doc|
#     next unless doc && doc[ params[:auth_field] ] && doc[ params[:variant_field] ]
#     author_variants[ doc[ params[:auth_field] ] ].merge doc[ params[:variant_field] ]
#   }
# 
#   return variants
# end
# 
# 
# # write the biblist to an output file, for debugging...
# def save_biblist_for_debug(biblist)
#   File.open('/tmp/biblist.out', 'w') { |f|
#     biblist.each { |bib| f.puts(bib) }
#   }
# end
# 
# def cleanup_age_param(age)
#   # if unset, return 365 (one  year)
#   return 365 unless age
#   # if set, convert to integer.  Raise if unable to convert.
#   raise "'age' needs to be integer, zero or more" unless age.match /^\d+$/
#   return age.to_i
# end


##################################################
####   One-By-One processing approach below   ####
##################################################



# Given a list of bib IDs, 
# lookup Authority variants for Authors, Subject Topics
# Skip records which have been processed in the last AGE days
def add_variants_to_biblist(biblist, age)
  raise "add_variants_to_biblist(biblist) not passed an array of bibs!" unless biblist and biblist.kind_of?(Array)

  # write the biblist to an output file, for debugging...
  File.open('/tmp/biblist.out', 'w') { |f|
    biblist.each { |bib| f.puts(bib) }
  }

  if age
    raise "'age' needs to be integer, zero or more" unless age.match /^\d+$/
    age = age.to_i
  else
    age = 365
  end

  # so that our progress dots print right away
  $stdout.sync = true

  puts "Adding author/subject variants to #{biblist.size} bibs"
  puts "(skipping records if last lookup was within #{age} days)"

  # Used throughout to gather overall stats
  @stats = {}

  counter = 0
  statuses = {}
  statuses['failure'] = 0
  # How many lookup/replace failures before giving up?
  failure_limit = 20
  biblist.each do |bib|
    begin
      counter = counter + 1
      print "." if (counter % 100) == 0
      # returns string status messages, count how many per msg
      status = add_variants_to_bib(bib, age)
      statuses[status] = (statuses[status] || 0) + 1
    rescue => ex
      statuses['failure'] = statuses['failure'] + 1
      if statuses['failure'] >= failure_limit
        puts "Reached max failures (#{failure_limit}) - giving up."
        return
      end

      first_line = ex.backtrace.first
      ex.set_backtrace([])
      puts "-- failure for bib #{bib}: #{ex.message}"
      puts first_line
      # puts "failure for bib #{bib}"
    end
  end

  # Add a newline after printing all the status dots
  puts ""

  # A final commit after the full biblist is processed
  begin
    BIB_SOLR.commit  # Slow......
  rescue => ex
    puts "Exception commiting to bibliographic Solr: #{ex.message}"
  end

  statuses.each { |k,v|
    puts "#{k}: #{v} records"
  }
  @stats.each { |k,v|
    puts "#  #{k}: #{v.round(2)}"
  }
end

def add_variants_to_bib(bib, age = 365)
  raise "add_variants_to_bib(bib) not passed a bib!" unless bib
  raise "add_variants_to_bib(bib) has no age param!" unless age

  # Collect variants.  
  author_variants = []
  subject_variants = []

  # fetch the authorizied forms from the bib
  params = {q: "id:#{bib}", facet: 'off',
      fl: 'id,author_facet,subject_topic_facet,subject_geo_facet,geo_subdivision_txt,authorities_dt'
  }

  # timing metrics...
  startTime = Time.now

  response = BIB_SOLR.get 'select', params: params

  # timing metrics...
  elapsed = Time.now - startTime
  key = "bib get total time (sec)"
  @stats[key] = (@stats[key] || 0) + elapsed.round(2)
  key = "bib get count"
  @stats[key] = (@stats[key] || 0) + 1


  return 'no such bib' unless response && response["response"]["docs"].size > 0

  authorities_dt = response["response"]["docs"].first['authorities_dt']
  bib_authors = response["response"]["docs"].first['author_facet']
  bib_subjects = response["response"]["docs"].first['subject_topic_facet']
  bib_geos = response["response"]["docs"].first['subject_geo_facet'] || []
  bib_geo_subdivs = response["response"]["docs"].first['geo_subdivision_txt'] || []

  # If the age of the record is less than threshold, don't update it
  # puts "DEBUG  authorities_dt=[#{authorities_dt}]  age=[#{age}]"
  if authorities_dt && ((DateTime.now - Date.parse(authorities_dt)).to_i < age)
    return "skipped"
  end

  if ENV["AUTHORITIES_DEBUG"]
    puts "AUTHORITIES_DEBUG --- bib values ---"
    puts "AUTHORITIES_DEBUG: id=#{response["response"]["docs"].first['id']}"
    puts "AUTHORITIES_DEBUG: bib_authors=#{bib_authors}"
    puts "AUTHORITIES_DEBUG: bib_subjects=#{bib_subjects}"
    puts "AUTHORITIES_DEBUG: bib_geos=#{bib_geos}"
    puts "AUTHORITIES_DEBUG: bib_geo_subdivs=#{bib_geo_subdivs}"
  end

  # Lookup variants in the authorities datastore
  # author_variants = lookup_author_variants(bib_authors)
  # subject_variants = lookup_subject_variants(bib_subjects)
  # geo_variants = lookup_geo_variants(bib_geos + bib_geo_subdivs)
  author_variants   = lookup_variants(bib_authors)
  subject_variants  = lookup_variants(bib_subjects)
  geo_variants      = lookup_variants(bib_geos + bib_geo_subdivs)

  if ENV["AUTHORITIES_DEBUG"]
    puts "AUTHORITIES_DEBUG --- variants found ---"
    puts "AUTHORITIES_DEBUG: author_variants=#{author_variants}"
    puts "AUTHORITIES_DEBUG: subject_variants=#{subject_variants}"
    puts "AUTHORITIES_DEBUG: geo_variants=#{geo_variants}"
  end

  # Always update the bib record with today's timestamp for last-lookup date.
  # Also add any author / subject / geo variants that we found.
  params = { id: bib,
             authorities_dt: {set: Time.now.utc.iso8601}
            }
  if author_variants && author_variants.size > 0
    params[:author_variant_txt] = {set: author_variants.flatten.uniq }
  end
  if subject_variants && subject_variants.size > 0
    params[:subject_variant_txt] = {set: subject_variants.flatten.uniq }
  end
  if geo_variants && geo_variants.size > 0
    params[:geo_variant_txt] = {set: geo_variants.flatten.uniq }
  end
  if ENV["AUTHORITIES_DEBUG"]
    puts "AUTHORITIES_DEBUG: params:\n#{params}"
  end

  # timing metrics...
  startTime = Time.now

  # Atomic update
  response = BIB_SOLR.update data: Array.wrap(params).to_json,
          headers: { 'Content-Type' => 'application/json' }

  # timing metrics...
  elapsed = Time.now - startTime
  key = "bib updates total time (sec)"
  @stats[key] = (@stats[key] || 0) + elapsed.round(2)
  key = "bib updates count"
  @stats[key] = (@stats[key] || 0) + 1

  return "success"
end

# def lookup_author_variants(bib_authors)
#   return unless bib_authors
#   bib_authors.map { |author|
#     # lookup_variants(author, 'author_t', 'author_variant_t')
#     lookup_variants(author, 'authorized_ss', 'variant_t')
#   }
# end
# 
# def lookup_subject_variants(bib_subjects)
#   return unless bib_subjects
#   bib_subjects.map { |subject|
#     # lookup_variants(subject, 'subject_t', 'subject_variant_t')
#     lookup_variants(subject, 'authorized_ss', 'variant_t')
#   }
# end
# 
# def lookup_geo_variants(bib_geos)
#   return unless bib_geos
#   bib_geos.map { |geo|
#     # lookup_variants(geo, 'geo_t', 'geo_variant_t')
#     lookup_variants(geo, 'authorized_ss', 'variant_t')
#   }
# end

# def lookup_variants(authorized_forms, authorized_field_name, variant_field_name)
def lookup_variants(authorized_forms)
  return unless authorized_forms

  query = build_authorized_forms_query(authorized_forms)

  # safe_authorized_form = authorized_form.gsub(/"/, '\"')
  #safe_authorized_form = CGI.escape authorized_form
  # CGI.escape() does too much.  It produces the following:
  #   :q=>"authorized_t:\"Aleksievich%2C+Svetlana%2C+1948-\""
  # which doesn't hit in Solr
  params = { qt: 'select',
      # Theoretically, our query is precise enough that we don't need
      # to restrict to only the first returned row.
      # rows: 1,
      # q: "#{authorized_field_name}:\"#{safe_authorized_form}\"",
      # fl: "id,#{authorized_field_name},#{variant_field_name}",
      q: query,
      fl: 'id,authorized_ss,variant_t',
      facet: 'off'
  }
  if ENV["AUTHORITIES_DEBUG"]
    puts "AUTHORITIES_DEBUG: >>>  lookup_variants() params=#{params}"
  end

  # timing metrics...
  startTime = Time.now

  response = AUTHORITIES_SOLR.get 'select', params: params

  # timing metrics...
  elapsed = Time.now - startTime
  # key = "#{authorized_field_name} lookups total time (sec)"
  key = "authorized_ss lookups total time (sec)"
  @stats[key] = (@stats[key] || 0) + elapsed.round(2)
  # key = "#{authorized_field_name} lookups count"
  key = "authorized_ss lookups count"
  @stats[key] = (@stats[key] || 0) + 1

  # puts "DEBUG: response=#{response}"
  # return nil unless we at least got something
  return unless response &&
              response['response']['docs'].size > 0 &&
              response['response']['docs'].first['variant_t']

  # Given that we got something....

  # - validate that the number of rows returned.  For each term, we could 
  #   potentially find a term in LCSH and in LC Names and in MESH.
  #   There's a upper bound of three authority records per authorized term.
  #   If we find more than 3x records, that's an error.
  if response['response']['docs'].size > (authorized_forms.size * 3)
    raise "Too many authority records retrieved.  query=[#{query}] retrieved #{response['response']['docs'].size} rows."
  end

  # - merge all variants from all returned rows, return the array.
  # return response['response']['docs'].first['variant_t']
  return response['response']['docs'].map { |doc| doc['variant_t'] }.flatten
end


def build_authorized_forms_query(authorized_forms)
  authorized_forms.delete_if(&:blank?)

  authorized_forms.uniq.map { |term|
    'authorized_ss:"' + term.gsub(/"/, '\"') + '"'
  }.join(' OR ')

end


