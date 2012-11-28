
module Spectrum
  module Engines
    class Summon
      include ActionView::Helpers::NumberHelper
      include Rails.application.routes.url_helpers
      Rails.application.routes.default_url_options = ActionMailer::Base.default_url_options

      DEFAULT_PARAMS = {
      'newspapers' =>  {'spellcheck' => true, 's.ho' => true, 's.cmd' => 'addFacetValueFilters(ContentType, Newspaper Article)', 's.ff' => ['ContentType,or','SubjectTerms,or','Language,or']},
      'articles' =>  {'spellcheck' => true, 's.ho' => true, 's.cmd' => 'addFacetValueFilters(ContentType, Newspaper Article:t)', 's.ff' => ['ContentType,or','SubjectTerms,or','Language,or']},
      'ebooks' => {'spellcheck' => true, 's.ho' => true, 's.cmd' => 'addFacetValueFilters(ContentType, Newspaper Article:t)', 's.fvf' => ['ContentType,eBook'], 's.ff' => ['ContentType,or,1,15','SubjectTerms,or,1,15','Language,or,1,15']},
      'dissertations' => {'spellcheck' => true, 's.ho' => true, 's.fvf' => ['ContentType,Dissertation'], 's.ff' => ['ContentType,or,1,15','SubjectTerms,or,1,15','Language,or,1,15']}
        }
        
      attr_reader :service

      attr_reader :source, :response, :results, :query 
      attr_accessor :params

      def initialize(options = {})
        @source = options.delete('source') 
        @params = (@source && options.delete('new_search')) ? DEFAULT_PARAMS[@source] : {}

        @config = options.delete('config') || APP_CONFIG['summon']
        @config.merge!(:url => 'http://api.summon.serialssolutions.com/2.0.0')
        @config.symbolize_keys!

        @debug_mode = options.delete('debug_mode') || false
        @debug_entries = Hash.arbitrary_depth

        @params.merge!(options)
        @params.delete('utf8')

        @service = ::Summon::Service.new(@config)

        Rails.logger.info "[SUMMON] config: #{@config.inspect}"

      end

      def search(extra_params = {})
        @response = @service.search(@params.merge(extra_params))
        @results = @response.documents

        return self
      end

      def current_page
        @response.query.page_number
      end

      def page_size
        @repsonse.query.page_size
      end
    end
  end
end

