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

# 
# # both of these need to know what datasource we're working with
#       @blacklight_config.connection_config[:url] = .....

      @source = $active_source


      Rails.logger.debug "REPO  Spectrum::SolrRepository#initialize @source=[#{@source}]"
# raise
    end

    def connection
      # raise
      Rails.logger.debug "REPO  Spectrum::SolrRepository#connection()"
      Rails.logger.debug "REPO  @connection=#{@connection.inspect}"

      # Blacklight::SolrRepository#connection
      # @connection ||= RSolr.connect(connection_config)
      # Example from Blacklight Wiki:
      # https://github.com/projectblacklight/blacklight/wiki/Solr-Configuration
      # @connection ||= RSolr::Custom::Client.new :user => current_user.id
      # Spectrum::SearchEngines::Solr#connection
      # @solr ||= Solr.generate_rsolr(@source, @solr_url)

       @connection ||= build_connection(@source, @solr_url)
    end

    protected

    def build_connection(source, solr_url = nil)
      # raise
      Rails.logger.debug "REPO  Spectrum::SolrRepository#build_connection(#{source})"
      if source.in?('academic_commons', 'ac_dissertations')
        RSolr.connect(url: APP_CONFIG['ac2_solr_url'])
      elsif source.in?('geo')
        RSolr.connect(url: APP_CONFIG['geo_solr_url'])
      elsif source.in?('dlc')
        RSolr.connect(url: APP_CONFIG['dlc_solr_url'])
      elsif solr_url
        RSolr.connect(url: solr_url)
      else
        RSolr.connect(Blacklight.connection_config)
      end
    end

  end
end

