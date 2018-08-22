module Spectrum
  class SolrRepository < Blacklight::Solr::Repository
    attr_accessor :source, :solr_url


    # Blacklight search_helper has this:
    # 
    # def repository_class
    #   blacklight_config.repository_class
    # end
    # 
    # def repository
    #   @repository ||= repository_class.new(blacklight_config)
    # end

    # Our application controller over-rides repository_class to point
    # to this class.

    # So... this class needs to handle new() in a CLIO-specific way.

    def initialize blacklight_config
      # BL
      # @blacklight_config = blacklight_config

      # CLIO
      # def repository
      #   @repository ||= Spectrum::SolrRepository.new(blacklight_config)
      #   @repository.source = @source
      #   @repository.solr_url = @solr_url
      #   @repository
      # end

      @blacklight_config = blacklight_config
# raise
      # How do I fetch CLIO's active_source from within BL class?
      # @source = active_source
      # @source = Thread.current[:active_source]

      Rails.logger.debug "REPO  Spectrum::SolrRepository#initialize @source=[#{@source}]"
# raise
    end

    def connection
# puts "333"
      # raise
      Rails.logger.debug "REPO  Spectrum::SolrRepository#connection()"
      Rails.logger.debug "REPO  before: @connection=#{@connection.inspect}"

      # Blacklight::SolrRepository#connection
      # @connection ||= RSolr.connect(connection_config)

      # Example from Blacklight Wiki:
      # https://github.com/projectblacklight/blacklight/wiki/Solr-Configuration
      # @connection ||= RSolr::Custom::Client.new :user => current_user.id
      # @connection ||= build_connection(@source, @solr_url)
      @connection ||= build_connection()
      Rails.logger.debug "REPO  after(@blacklight_config.source):  @connection=#{@connection.inspect}"
      return @connection
    end

    protected

    # Rails 4:
    # def build_connection(source, solr_url = nil)
    #   # raise
    #   Rails.logger.debug "REPO  Spectrum::SolrRepository#build_connection(#{source})"
    #   if source.in?('academic_commons', 'ac_dissertations')
    #     RSolr.connect(url: APP_CONFIG['ac2_solr_url'])
    #   elsif source.in?('geo', 'geo_cul')
    #     RSolr.connect(url: APP_CONFIG['geo_solr_url'])
    #   elsif source.in?('dlc')
    #     RSolr.connect(url: APP_CONFIG['dlc_solr_url'])
    #   elsif solr_url
    #     RSolr.connect(url: solr_url)
    #   else
    #     RSolr.connect(Blacklight.connection_config)
    #   end
    # end

   # def build_connection(source, solr_url = nil)
   def build_connection
# puts "444"
     source = @blacklight_config.source
# puts ">>>  build_connection() source=#{source}"

if source == 'articles' || source == 'library_web'
  begin
    raise "WRONG"
  rescue => e
    # puts "build_connection() source=#{source} @source=#{@source} Thread.current[:active_source]=#{Thread.current[:active_source]}"
    puts e.backtrace.join("\n")
    raise
  end
end

     url = case source
     # when 'academic_commons', 'ac_dissertations'
     #   APP_CONFIG['ac2_solr_url']
     when 'geo', 'geo_cul'
       APP_CONFIG['geo_solr_url']
     when 'dlc'
       APP_CONFIG['dlc_solr_url']
     else
       # Instead of itemizing all the possible sources, just
       # default to our primary Solr connection.
       # raise "build_connection: unknown source [#{source}]!"
       connection_config[:url]
     end
# puts "url=#{url}"
# puts "connection_config=#{connection_config.to_s}"
# puts "connection_config merged=#{connection_config.merge(adapter: connection_config[:http_adapter], url: url).to_s}"
     RSolr.connect(connection_config.merge(adapter: connection_config[:http_adapter], url: url))
   end

  end
end

