module Spectrum
  class SolrRepository < Blacklight::SolrRepository
    attr_accessor :source, :solr_url

    def connection
      Rails.logger.debug "Spectrum::SolrRepository#connection()"
      Rails.logger.debug "@connection=#{@connection.inspect}"

      # Blacklight::SolrRepository#connection
      # @connection ||= RSolr.connect(connection_config)
      # Example from Blacklight Wiki:
      # https://github.com/projectblacklight/blacklight/wiki/Solr-Configuration
      # @connection ||= RSolr::Custom::Client.new :user => current_user.id
      # Spectrum::SearchEngines::Solr#connection
      # @solr ||= Solr.generate_rsolr(@source, @solr_url)

       @connection ||= generate_rsolr(@source, @solr_url)
    end

    def generate_rsolr(source, solr_url = nil)
      Rails.logger.debug "Spectrum::SolrRepository#generate_rsolr(#{source})"
      if source.in?('academic_commons', 'ac_dissertations')
        RSolr.connect(url: APP_CONFIG['ac2_solr_url'])
      elsif solr_url
        RSolr.connect(url: solr_url)
      else
        RSolr.connect(Blacklight.connection_config)
      end
    end

  end
end

