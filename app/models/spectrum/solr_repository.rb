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

    def initialize(blacklight_config)
      @blacklight_config = blacklight_config
    end

    def connection
      # Example from Blacklight Wiki:
      # https://github.com/projectblacklight/blacklight/wiki/Solr-Configuration
      # @connection ||= RSolr::Custom::Client.new :user => current_user.id
      # @connection ||= build_connection(@source, @solr_url)
      @connection ||= build_connection
    end

    protected


    def build_connection
      source = @blacklight_config.source

      if source == 'articles' || source == 'library_web'
        begin
          raise 'WRONG'
        rescue => e
          puts e.backtrace.join("\n")
          raise
        end
      end

      url = case source
            when 'geo', 'geo_cul'
              APP_CONFIG['geo_solr_url']
            when 'dlc'
              APP_CONFIG['dlc_solr_url']
            else
              # default to our primary Solr connection.
              connection_config[:url]
      end
      RSolr.connect(connection_config.merge(adapter: connection_config[:http_adapter], url: url))
    end
  end
end
