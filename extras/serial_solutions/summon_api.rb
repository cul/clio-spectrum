
module SerialSolutions
  class SummonAPI
    include Rails.application.routes.url_helpers
    Rails.application.routes.default_url_options = ActionMailer::Base.default_url_options
    
    attr_reader :service, :search, :query

    DEFAULT_OPTIONS = {
      'articles' =>  {'spellcheck' => true, 's.cmd' => 'addFacetValueFilters(ContentType, Newspaper Article:t)', 's.ff' => ['ContentType,or','SubjectTerms,or','Language,or']},
      'ebooks' => {'spellcheck' => true, 's.cmd' => 'addFacetValueFilters(ContentType, Newspaper Article:t)', 's.fvf' => ['ContentType,eBook'], 's.ff' => ['ContentType,or,1,15','SubjectTerms,or,1,15','Language,or,1,15']}
        }
        
    def initialize(params = {}) 
      @config = params.delete(:config) || APP_CONFIG[:summon]

      if params.delete(:new_search)
        category = params.delete(:category) || 'articles'
        params.reverse_update(DEFAULT_OPTIONS[category])
      end

      @service = Summon::Service.new(@config)
      @search = @service.search(params)
      @query = @search.query
      @query_hash = @query.to_hash
    end

    def previous_page
      set_page(@query_hash['s.pn'].to_i - 1)
    end

    def next_page
      set_page(@query_hash['s.pn'].to_i + 1)
    end

    def set_page(page)
      new_page = [[1, page.to_i].max, @search.page_count].min
      search_merge('s.pn' => new_page)
    end

    private

    def search_merge(params={})
      article_search_path(@query_hash.merge(params))
    end
  end
end
