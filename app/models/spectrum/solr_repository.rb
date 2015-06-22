module Spectrum
  class SolrRepository < Blacklight::SolrRepository
    attr_accessor :source, :solr_url

    def blacklight_solr
      Rails.logger.debug "Spectrum::SolrRepository#blacklight_solr()"
      Rails.logger.debug "@blacklight_solr=#{@blacklight_solr.inspect}"

      # Blacklight::SolrRepository#blacklight_solr
      # @blacklight_solr ||= RSolr.connect(blacklight_solr_config)
      # Example from Blacklight Wiki:
      # https://github.com/projectblacklight/blacklight/wiki/Solr-Configuration
      # @blacklight_solr ||= RSolr::Custom::Client.new :user => current_user.id
      # Spectrum::SearchEngines::Solr#blacklight_solr
      # @solr ||= Solr.generate_rsolr(@source, @solr_url)

       @blacklight_solr ||= generate_rsolr(@source, @solr_url)
    end

    def generate_rsolr(source, solr_url = nil)
      Rails.logger.debug "Spectrum::SolrRepository#generate_rsolr(#{source})"
      if source.in?('academic_commons', 'ac_dissertations')
        RSolr.connect(url: APP_CONFIG['ac2_solr_url'])
      elsif source.in?('dcv')
        RSolr.connect(url: APP_CONFIG['dcv_solr_url'])
      elsif solr_url
        RSolr.connect(url: solr_url)
      else
        RSolr.connect(Blacklight.solr_config)
      end
    end

  end
end

