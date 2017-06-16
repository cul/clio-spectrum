require 'time'    # gives us ISO time formatting
require 'marc'

require File.join(Rails.root.to_s, 'config', 'initializers/aaa_load_app_config.rb')

# EXTRACT_SCP_SOURCE = APP_CONFIG['extract_scp_source']

EXTRACTS =  ["full", "incremental", "cumulative", "subset", "law", "test",
             "auth_incremental", "auth_full", "auth_subset"]

BIB_SOLR_URL = Blacklight.connection_config[:url]
BIB_SOLR = RSolr.connect(url: BIB_SOLR_URL)
AUTHORITIES_SOLR = RSolr.connect(url: APP_CONFIG['authorities_solr_url'])

def solr_delete_ids(ids)
  retries = 5
  begin
    ids = ids.listify.collect { |x| x.strip}
    puts_and_log(ids.length.to_s + " deleting", :debug)
    Blacklight.default_index.connection.delete_by_id(ids)

    puts_and_log("Committing changes", :debug)
    Blacklight.default_index.connection.commit

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

def puts_and_log(msg, level = :info, params = {})
  time = Time.now.to_formatted_s(:time)
  full_msg = time + " " + level.to_s + ": " + msg.to_s
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

def xml_clean(filename)
  raise "xml_clean() passed empty filename!" if filename.empty?

  # clean_file = "#{filename}.clean"
  # File.open(filename).each do |line|
  #   tempfile.puts line.gsub(regexp, replacement)
  # end

  File.open("#{filename}.clean", 'w') do |tempfile|
    File.open(filename).each do |line|
      tempfile.puts line.gsub(/[\x01-\x08\x0b\x0c\x0e-\x1f]/, '?')
    end
    tempfile.fsync
    tempfile.close
    # stat = File.stat(filename)
    # FileUtils.chown stat.uid, stat.gid, tempfile.path
    # FileUtils.chmod stat.mode, tempfile.path
    FileUtils.mv tempfile.path, filename
  end

end








