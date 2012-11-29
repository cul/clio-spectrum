module Spectrum
  module Engines
    class Catalog < BaseEngine

      def initialize(params)
        configure_search('catalog')
        params['rows'] = 15
        params['q'] = query

        @docs = solr_results,
        @count = solr_response['response']['numFound'].to_i,
        @url = url_for(:controller => 'catalog', :action => 'index', :q => params['q'])
      end
    end
  end
end
