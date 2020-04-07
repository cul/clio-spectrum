require 'time' # gives us ISO time formatting
require 'marc'
require 'open3'

require 'rake'

require File.join(Rails.root.to_s, 'config', 'initializers/aaa_load_app_config.rb')


EXTRACTS = %w(full incremental cumulative subset law auth recap).freeze

# process large 'deletes' files in batches of this many
DELETES_SLICE = 1000

# BIB_SOLR_URL = Blacklight.connection_config[:url]
# BIB_SOLR = RSolr.connect(url: BIB_SOLR_URL)

AUTHORITIES_SOLR = RSolr.connect(url: APP_CONFIG['authorities_solr_url'])
AUTHORITIES_SOLR_FAILURES = 0

def reset_authorities_solr
  # backoff
  sleep 1
  AUTHORITIES_SOLR_FAILURES = AUTHORITIES_SOLR_FAILURES + 1
  AUTHORITIES_SOLR.close unless AUTHORITIES_SOLR.blank?
  AUTHORITIES_SOLR = RSolr.connect(url: APP_CONFIG['authorities_solr_url'])
end

def setup_ingest_logger
  # Redirect logger to stderr for our ingest tasks tasks
  Rails.logger = Logger.new(STDERR)
  # Then also write messages to a distinct 'ingest' log file
  ingest_log_file = File.join(Rails.root, 'log', "#{Rails.env}_ingest.log")
  ingest_log_logger = Logger.new(ingest_log_file)
  Rails.logger.extend(ActiveSupport::Logger.broadcast(ingest_log_logger))
end

def solr_delete_ids(solr_connection, ids)
  retries = 3
  begin
    ids = ids.listify.collect(&:strip)
    Rails.logger.debug("deleting #{ids.size} records...") if ENV['DEBUG']
    solr_connection.delete_by_id(ids)

    Rails.logger.debug('committing changes...') if ENV['DEBUG']
    solr_connection.commit

  rescue Timeout::Error
    Rails.logger.info('Timed out!')
    if retries <= 0
      Rails.logger.error('Out of retries, stopping delete process.')
      raise
    end

    Rails.logger.info('Trying again.')
    retries -= 1
    retry
  end
end

# def puts_and_log(msg, level = :info, params = {})
#   time = Time.now.to_formatted_s(:time)
#   full_msg = time + " " + level.to_s + ": " + msg.to_s
#   puts full_msg
#   unless @logger
#     @logger = Logger.new(File.join(Rails.root, "log", "#{Rails.env}_ingest.log"))
#     @logger.formatter = Logger::Formatter.new
#   end
#
#   # This writes to the app's regular log file
#   if defined?(Rails) && Rails.logger
#     Rails.logger.send(level, msg)
#   end
#
#   @logger.send(level, msg)
#
#   if params[:alarm]
#     raise full_msg
#   end
#
# end

def clean_ingest_file(filename)
  raise 'clean_ingest_file() passed empty filename!' if filename.blank?
  raise "clean_ingest_file() passed non-existent filename '#{filename}'!" unless File.exist?(filename)

  File.open("#{filename}.clean", 'w') do |tempfile|
    File.open(filename).each do |line|
      # cleanup bad chars in leader
      if match = line.match(/(.*<leader>)(.+)(<\/leader>.*)/)
        before, leader, after = match.captures
        leader[5]  = 'n' unless leader[5] =~ /[acdnp]/
        leader[8]  = ' ' unless leader[8] =~ /[ a]/
        leader[9]  = 'a' unless leader[9] =~ /[ a]/
        leader[17] = 'u' unless leader[17] =~ /[ a-zA-Z0-9]/
        leader[18] = 'u' unless leader[18] =~ /[ acinpru]/
        leader[20..23] = '4500'
        line = before + leader + after
      end

      # NEXT-1446, random one-off failure (subfield '"')
      next if line =~ /code="""/

      # replace invalid bytes throughout
      tempfile.puts line.gsub(/[\x01-\x08\x0b\x0c\x0e-\x1f]/, '?')
    end
    tempfile.fsync
    tempfile.close
    FileUtils.mv tempfile.path, filename
  end
end
