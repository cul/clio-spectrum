
module Spectrum
  module Engines
    class Summon
      include ActionView::Helpers::NumberHelper
      include Rails.application.routes.url_helpers
      Rails.application.routes.default_url_options = ActionMailer::Base.default_url_options

      DEFAULT_PARAMS = {
      'newspapers' =>  {'spellcheck' => true, 's.ho' => true, 's.cmd' => 'addFacetValueFilters(ContentType, Newspaper Article)', 's.ff' => ['ContentType,and,1,5','SubjectTerms,and,1,10','Language,and,1,5']},
      'articles' =>  {'spellcheck' => true, 's.ho' => true, 's.cmd' => 'addFacetValueFilters(ContentType, Newspaper Article:t)', 's.ff' => ['ContentType,and,1,5','SubjectTerms,and,1,10','Language,and,1,5']},
      'ebooks' => {'spellcheck' => true, 's.ho' => true, 's.cmd' => 'addFacetValueFilters(ContentType, Newspaper Article:t)', 's.fvf' => ['ContentType,eBook'], 's.ff' => ['ContentType,and,1,5','SubjectTerms,and,1,10','Language,and,1,5']},
      'dissertations' => {'spellcheck' => true, 's.ho' => true, 's.fvf' => ['ContentType,Dissertation'], 's.ff' => ['ContentType,and,1,5','SubjectTerms,and,1,10','Language,and,1,5']}
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

        @params['s.cmd'] ||= ''
        @params['s.q'] ||= ''
        @params['s.fq'] ||= ''

        @params['s.role'] = options.delete('authorized') ? 'authenticated' : ''

        if @params['s.fq'].kind_of?(Hash)
          new_fq = []
          @params['s.fq'].each_pair do |name, value|
            new_fq << "#{name}:#{value}" unless value.to_s.empty?
          end
          @params['s.fq'] = new_fq
        end

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

      FACET_ORDER = %w{ContentType_mfacet SubjectTerms_mfacet Language_s}

      def facets
        @search.facets.sort_by { |facet| (ind = FACET_ORDER.index(facet.field_name)) ? ind : 999 }
      end

      def pre_facet_options_with_links()
        facet_options = []

        is_full_text = facet_value('IsFullText') == 'true'
        is_full_cmd = !is_full_text ? "addFacetValueFilters(IsFullText, true)" : "removeFacetValueFilter(IsFullText,true)"
        facet_options << {
          style: :checkbox,
          value: is_full_text,
          link: by_source_search_cmd(is_full_cmd),
          name: "Full text online only"
        }

        is_scholarly = facet_value('IsScholarly') == 'true'
        is_scholarly_cmd = !is_scholarly ? "addFacetValueFilters(IsScholarly, true)" : "removeFacetValueFilter(IsScholarly,true)"
        facet_options << {
          style: :checkbox,
          value: is_scholarly,
          link: by_source_search_cmd(is_scholarly_cmd),
          name: "Scholarly publications only"
        }

        exclude_newspapers = @search.query.facet_value_filters.any? { |fvf| fvf.field_name == "ContentType" && fvf.value == "Newspaper Article" && fvf.negated? }
        exclude_cmd = !exclude_newspapers ? "addFacetValueFilters(ContentType, Newspaper Article:t)" : "removeFacetValueFilter(ContentType, Newspaper Article)"



        facet_options << {
          style: :checkbox,
          value: exclude_newspapers,
          link: by_source_search_cmd(exclude_cmd),
          name: "Exclude Newspaper Articles"
        }


        all_holdings_only = @search.query.holdings_only_enabled == true
        facet_options << {
          style: :checkbox,
          value: all_holdings_only,
          link: by_source_search_cmd("setHoldingsOnly(#{!all_holdings_only})"),
          name: "Columbia's collection only"
        }

        facet_options
      end

      def newspapers_excluded?()
        @search.query.facet_value_filters.any? { |fvf| fvf.field_name == "ContentType" && fvf.value == "Newspaper Article" && fvf.negated? }
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
        elsif @search.query.sort.field_name == "PublicationDate"
          if @search.query.sort.sort_order == "desc"
            "Published Latest"
          else
            "Published Earliest"
          end


        end
      end


      def constraints_with_links
        constraints = []
        @search.query.text_queries.each do |q|
          constraints << [q['textQuery'], by_source_search_cmd(q['removeCommand'])]
        end
        @search.query.text_filters.each do |q|
          filter_text = q['textFilter'].to_s.sub(/^([^\:]+)Combined:/,'\1:').sub(':', ': ')
          constraints << [filter_text, by_source_search_cmd(q['removeCommand'])]
        end
        @search.query.facet_value_filters.each do |fvf|
          unless fvf.field_name.titleize.in?("Is Scholarly", "Is Full Text")
            facet_text = "#{fvf.negated? ? "Not " : ""}#{fvf.field_name.titleize}: #{fvf.value}"
            constraints << [facet_text, by_source_search_cmd(fvf.remove_command)]
          end
        end
        @search.query.range_filters.each do |rf|
          facet_text = "#{rf.field_name.titleize}: #{rf.range.min_value}-#{rf.range.max_value}"
          constraints << [facet_text, by_source_search_cmd(rf.remove_command)]
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

      def page_size_with_links
        [10,20,50,100].collect do |page_size|
          [by_source_search_cmd("setPageSize(#{page_size})"), page_size]
        end

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
        by_source_search_modify('s.pn' => [total_pages, [page_num, 1].max].min)
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

      def by_source_search_cmd(cmdText)
        by_source_search_modify('s.cmd' => cmdText)
      end

      def by_source_search_modify(cmd = {})
        by_source_search_link(@search.query.to_hash.merge(cmd))
      end

      private

      def facet_value(field_name)
        fvf = @search.query.facet_value_filters.detect { |x| x.field_name == field_name }
        fvf ? fvf.value : nil
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

