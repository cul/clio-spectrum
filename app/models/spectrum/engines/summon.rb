
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
        

      attr_reader :source, :errors, :search
      attr_accessor :params

      def initialize(options = {})
        @source = options.delete('source') || options.delete(:source) 
        @params = (@source && options.delete('new_search')) ? DEFAULT_PARAMS[@source] : {}

        @config = options.delete('config') || APP_CONFIG['summon']
        @config.merge!(:url => 'http://api.summon.serialssolutions.com/2.0.0')
        @config.symbolize_keys!

        @search_url = options.delete('search_url')

        @debug_mode = options.delete('debug_mode') || false
        @debug_entries = Hash.arbitrary_depth

        @params.merge!(options)
        @params.delete('utf8')

        @errors = nil
        begin 
          @service = ::Summon::Service.new(@config)

          Rails.logger.info "[Spectrum][Summon] params: #{@params}"

          @search = @service.search(@params)

        rescue Exception => e
          Rails.logger.error "[Spectrum][Summon] error: #{e.message}"
          @errors = e.message
        end
      end

      def results
        documents
      end
      def search_path
        @search_url || by_source_search_link(@params)
      end

      def current_sort_name
        if @search.query.sort.nil?
          "Relevance"
        elsif @search.query.field_name == "PublicationDate"
          if @search.query.sort_order == "desc"
            "Published Latest"
          else
            "Published Earliest"
          end


        end
      end

      def constraints_with_links
        constraints = []
        @search.query.text_queries.each do |q|
          constraints << [q['textQuery'], by_source_search_remove(q['removeCommand'])]
        end
        @search.query.facet_value_filters.each do |fvf|
          facet_text = "#{fvf.negated? ? "NOT " : ""}#{fvf.field_name.titleize}: #{fvf.value}"
          constraints << [facet_text, by_source_search_remove(fvf.remove_command)]
        end
        constraints
      end

      def sorts_with_links
        [
          [by_source_search_cmd('setSortByRelevancy()'), "Relevance"],
          [by_source_search_cmd('setSort(PublicationDate:desc)'), "Published Latest"],
          [by_source_search_cmd('setSort(PublicationDate:asc)'), "Published Earliest"]
        ]
      end

      def successful?
        @errors.nil?
      end


      def documents
        @search.documents
      end

      def start_over_link
        by_source_search_link('new_search' => true)
      end

      def previous_page?
        current_page > 1 && total_pages > 1
      end

      def previous_page_path
        set_page_path(current_page - 1) 
      end

      def next_page?
        total_pages > current_page && 20 > current_page
      end

      def next_page_path
        set_page_path(current_page + 1)
      end

      def set_page_path(page_num)
        by_source_search_cmd('s.pn' => [total_pages, [page_num, 1].max].min)
      end

      def page_size
        @search.query.page_size.to_i
      end

      def total_items
        @search.record_count
      end

      def start_item
        (page_size * (current_page - 1)) + 1
      end

      def end_item
        [start_item + page_size - 1, total_items].min
      end

      def total_pages
        @search.page_count
      end

      def current_page
        @search.query.page_number
      end

      def page_size
        @search.query.page_size
      end


      private
  

      def by_source_search_remove(cmdText)
        by_source_search_cmd('s.cmd' => cmdText)
      end
      def by_source_search_cmd(cmd = {})
        by_source_search_link(@search.query.to_hash.merge(cmd))
      end

      def by_source_search_link(params = {})
        case @source
        when 'newspapers'
          newspapers_index_path(params)
        when 'articles'
          articles_index_path(params)
        else
          articles_index_path(params)
        end
      end
    end
  end
end

