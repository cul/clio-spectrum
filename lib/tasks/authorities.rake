
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
      puts_and_log("Unknown extract: #{ENV['EXTRACT']}", :error) unless extract

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

      BIB_SOLR.commit  # Slow......

    end

    desc "download and ingest latest authority files"
    task :process => :environment do
      Rake::Task["authorities:extract:download"].execute
      puts_and_log("Downloading successful.")

      Rake::Task["authorities:extract:ingest"].execute
      puts_and_log("Ingest successful.")
    end
  end

  namespace :add_to_bib do

    task :by_extract, [:extract, :age] do |t, args|
      extract = args[:extract]
      raise "usage:  authorities:add_by_extract[incremental]" unless extract

      biblist = []
      extract_files = Dir.glob(File.join(Rails.root, "tmp/extracts/#{extract}/current/*.mrc"))
      extract_files.each do |file|
        puts "file #{file}..."
        reader = MARC::Reader.new(file)
        for record in reader
          biblist.push record['001']
        end
      end

      puts "found #{biblist.size} bibs.  Adding authority variants..."
      biblist.each do |bib|
        Rake::Task["authorities:bib:add_variants"].execute bib: bib, age: args[:age]
      end
      puts "done."
    end

    task :by_range, [:start, :stop, :age] do |t, args|
      raise "usage:  authorities:add_by_range[10000,11000]" unless args[:start] and args[:stop]
      biblist = ( args[:start] .. args[:stop] ).to_a

      # puts "DEBUG biblist=#{biblist.inspect}"
      # biblist.each do |bib|
      #   Rake::Task["authorities:bib:add_variants"].execute bib: bib, age: args[:age]
      # end
      add_variants_to_biblist(biblist, args[:age])

      # # Do we need this?
      # BIB_SOLR.commit  # Slow......

    end

    task :by_bibfile, [:bib_file, :age] do |t, args|
      bibfile = args[:bib_file]
      # biblist = IO.readlines bibfile
      biblist = File.open(bibfile).readlines.map(&:strip)

      add_variants_to_biblist(biblist, args[:age])
      # 
      # biblist.each do |bib|
      #   Rake::Task["authorities:bib:add_variants"].execute bib: bib, age: args[:age]
      # end
      # 
      # # Do we need this?
      # BIB_SOLR.commit  # Slow......

    end

    desc "Get list of bib ids by running query against bib solr"
    task :by_query,  [:query, :age] do |t, args|
      query = args[:query]
      raise "usage:  authorities:add_to_bib:by_query['Miocardial infarction']" unless query

      puts "querying bib solr for '#{query}'..."
      cutoff = 1000
      response = BIB_SOLR.get 'select', params: {q: query, fl: 'id', rows: cutoff}
      raise "Error querying Bib Solr!" unless
          response && response['response'] && response['response']['docs']

      hits = response['response']['docs'].size
      puts "found #{hits} bibs."
      puts "(** cutoff at #{cutoff} bibs)" if hits >= cutoff
      puts "No hits - giving up." if hits == 0
      next if hits <= 1

      biblist = response['response']['docs'].map { |doc| doc['id'] }
      add_variants_to_biblist(biblist, args[:age])

    end
  end

#   namespace :bib do
# 
#     desc "Add Authority variants to bib records"
#     task :add_variants, [:bib, :age] do |t, args|
#       bib = args[:bib]
#       raise "bib:add_variants not passed :bib!" unless bib
# 
#       # default, trust authority lookups done within the last year
#       age = (args[:age] || "365").to_i
# 
#       # Collect variants.  If we find any, we'll update the bib
#       # subject_variants = []  # TODO
#       author_variants = []
# 
#       # fetch the authorizied forms from the bib
#       response = BIB_SOLR.get 'select', params: {q: "id:#{bib}", fl: 'author_facet,authorities_dt'}
#       next unless response && response["response"]["docs"].size > 0
# 
#       authorities_dt = response["response"]["docs"].first['authorities_dt']
#       authors = response["response"]["docs"].first['author_facet']
#       # subjects = response["response"]["docs"].first[...]   # TODO
# 
#       # If the age of the record is less than threshold, don't update it
#       next if authorities_dt && ((DateTime.now - Date.parse(authorities_dt)).to_i < age)
# 
#       Array(authors).each do |author|
#         response = AUTHORITIE S_SOLR.get 'select', params: {q: "author_t:\"#{author}\"", fl: 'id,author_t,author_variant_t', rows: 1, qt: 'select'}
#         next unless response &&
#                     response['response']['docs'].size > 0 &&
#                     response['response']['docs'].first['author_variant_t']
#         author_variants = author_variants + response['response']['docs'].first['author_variant_t']
#       end
# 
#       # Update the bib record with zero or more variants, 
#       # and a timestamp for when we last added authorities to this record.
#       # Atomic update bib record...
#       params = { id: bib,
#                  authorities_dt: {set: Time.now.utc.iso8601}
#                  # author_variant_txt: {set: author_variants.uniq.join(' ') }
#                  # subject_variant_txt: {set: subject_variants.uniq.join(' ') }  # TODO
#                 }
#       if author_variants.size > 0
#         params[:author_variant_txt] = {set: author_variants.uniq.join(' ') }
#       end
# # puts "params:\n#{params}"
#       response = BIB_SOLR.update data: Array.wrap(params).to_json,
#               headers: { 'Content-Type' => 'application/json' }
#     end
# 
#   end
# 
end



# Common logic in methods


# Given a list of bib IDs, 
# lookup Authority variants for Authors, Subject Topics
# Skip records which have been processed in the last AGE days
def add_variants_to_biblist(biblist, age)
  raise "add_variants_to_biblist(biblist) not passed an array of bibs!" unless biblist and biblist.kind_of?(Array)
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

  counter = 0
  statuses = {}
  statuses['failure'] = 0
  failure_limit = 5
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

  # A final commit after the full biblist is processed
  BIB_SOLR.commit  # Slow......

  statuses.each { |k,v|
    puts "#{k}: #{v} records"
  }
end

def add_variants_to_bib(bib, age = 365)
  raise "add_variants_to_bib(bib) not passed a bib!" unless bib
  raise "add_variants_to_bib(bib) has no age param!" unless age

  # Collect variants.  
  author_variants = []
  subject_variants = []

  # fetch the authorizied forms from the bib
  params = {q: "id:#{bib}", fl: 'author_facet,subject_topic_facet,authorities_dt'}
  response = BIB_SOLR.get 'select', params: params
  return 'no such bib' unless response && response["response"]["docs"].size > 0

  authorities_dt = response["response"]["docs"].first['authorities_dt']
  bib_authors = response["response"]["docs"].first['author_facet']
  bib_subjects = response["response"]["docs"].first['subject_topic_facet']

  # If the age of the record is less than threshold, don't update it
  # puts "DEBUG  authorities_dt=[#{authorities_dt}]  age=[#{age}]"
  if authorities_dt && ((DateTime.now - Date.parse(authorities_dt)).to_i < age)
    return "skipped"
  end

  # Lookup variants in the authorities datastore
  author_variants = lookup_author_variants(bib_authors)
  subject_variants = lookup_subject_variants(bib_subjects)
  # subject_variants = []

  # Always update the bib record with today's timestamp for last-lookup date.
  # Also add any author or subject variants that we found.
  params = { id: bib,
             authorities_dt: {set: Time.now.utc.iso8601}
            }
  if author_variants && author_variants.size > 0
    params[:author_variant_txt] = {set: author_variants.flatten.uniq.join(' ') }
  end
  if subject_variants && subject_variants.size > 0
    params[:subject_variant_txt] = {set: subject_variants.flatten.uniq.join(' ') }
  end
  # puts "DEBUG  params:\n#{params}"
  response = BIB_SOLR.update data: Array.wrap(params).to_json,
          headers: { 'Content-Type' => 'application/json' }
  return "success"
end

def lookup_author_variants(bib_authors)
  return unless bib_authors
  bib_authors.map { |author|
    lookup_variants(author, 'author_t', 'author_variant_t')
  }
end

def lookup_subject_variants(bib_subjects)
  return unless bib_subjects
  bib_subjects.map { |subject|
    lookup_variants(subject, 'subject_t', 'subject_variant_t')
  }
end

def lookup_variants(authorized_form, authorized_field_name, variant_field_name)
  safe_authorized_form = authorized_form.gsub(/"/, '\"')
  params = { qt: 'select', rows: 1,
      q: "#{authorized_field_name}:\"#{safe_authorized_form}\"",
      fl: "id,#{authorized_field_name},#{variant_field_name}" }
  # puts "DEBUG: params=#{params}"
  response = AUTHORITIES_SOLR.get 'select', params: params
  # puts "DEBUG: response=#{response}"
  return unless response &&
              response['response']['docs'].size > 0 &&
              response['response']['docs'].first[variant_field_name]
  return response['response']['docs'].first[variant_field_name]
end
