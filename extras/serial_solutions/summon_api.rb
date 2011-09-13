
module SerialSolutions
  class SummonAPI
    attr_reader :service
    def self.search(options = {})
      config = options.delete(:config) || APP_CONFIG[:summon]
      Summon::Service.new(config).search(options)
    end
     
    
    DEFAULT_OPTIONS = {
      'articles' =>  {'spellcheck' => true, 's.cmd' => 'addFacetValueFilters(ContentType, NewspaperArticle:t)', 's.ff' => ['ContentType,or','SubjectTerms,or','Language,or']},
      'ebooks' => {'spellcheck' => true, 's.cmd' => 'addFacetValueFilters(ContentType, NewspaperArticle:t)', 's.fvf' => ['ContentType,eBook'], 's.ff' => ['ContentType,or,1,15','SubjectTerms,or,1,15','Language,or,1,15']}
        }
    def self.search_new(category, options = {})
      merged_options = options.reverse_update(DEFAULT_OPTIONS[category])

      self.search(merged_options)

    end

    def self.search_articles(options ={})
      SerialSolutions::SummonAPI.search(merged_options)
    end
    
    def initialize(config = APP_CONFIG[:summon])
      @service = Summon::Service.new(APP_CONFIG[:summon])
    end

    def search(options = {})
      @service.search(options)
    end
  end
end
