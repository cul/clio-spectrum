
module Spectrum
  module Engines
    class Summon
      include ActionView::Helpers::NumberHelper
      include Rails.application.routes.url_helpers
      Rails.application.routes.default_url_options = ActionMailer::Base.default_url_options

      # These are ALWAYS in effect for Summon API queries
      # s.ff - how many options to retrieve for each filter field
      SUMMON_FIXED_PARAMS = {
        'spellcheck' => true,
        's.ff' => ['ContentType,and,1,5','SubjectTerms,and,1,10','Language,and,1,5']
      }.freeze

      # These source-specific params are ONLY FOR NEW SEARCHES
      # s.ho=<boolean>     Holdings Only Parameter, a.k.a., "Columbia's collection only"
      SUMMON_DEFAULT_PARAMS = {

        'newspapers' =>  {'s.ho' => 't',
                          's.cmd' => 'addFacetValueFilters(ContentType, Newspaper Article)'}.freeze,

        'articles' =>  {'s.ho' => 't',
                        's.cmd' => 'addFacetValueFilters(ContentType, Newspaper Article:t)'}.freeze,

        'ebooks' => { 's.ho' => 't',
                      's.cmd' => 'addFacetValueFilters(IsFullText, true)',
                      's.fvf' => ['ContentType,eBook']}.freeze,

        'dissertations' => { 's.ho' => 't',
                             's.fvf' => ['ContentType,Dissertation']}.freeze
        }.freeze


      attr_reader :source, :errors, :search
      attr_accessor :params

      # initialize() performs the actual API search, and
      # returns @search - a filled-in search structure, including query results.
      # input "options" are the CGI-param inputs, while
      # @params is a built-up parameters hash to pass to the Summon API
      def initialize(options = {})
        # Rails.logger.debug "initialize() options=#{options.inspect}"
        @source = options.delete('source') || options.delete(:source)
        @params = {}
        # These sources only come from bento-box aggregate searches, so enforce
        # the source-specific params without requires 'new_search' CGI param
        if @source && (@source == 'ebooks' || @source == 'dissertations')
          @params = SUMMON_DEFAULT_PARAMS[@source].dup
        # Otherwise, when source is Articles or Newspapers, we set source-specific default
        # params only for new searches.  Subsequent searches may change these values.
        elsif @source && options.delete('new_search')
          @params = SUMMON_DEFAULT_PARAMS[@source].dup
        end
        # @params = (@source && options.delete('new_search')) ? SUMMON_DEFAULT_PARAMS[@source].dup : {}
        @params.merge!(SUMMON_FIXED_PARAMS)

        @config = options.delete('config') || APP_CONFIG['summon']

        @config.merge!(:url => 'http://api.summon.serialssolutions.com/2.0.0')
        @config.symbolize_keys!

        @search_url = options.delete('search_url')

        @search_field = options.delete('search_field') || ''

        @debug_mode = options.delete('debug_mode') || false
        @debug_entries = Hash.arbitrary_depth

        @params.merge!(options)
        @params.delete('utf8')

        @params['s.cmd'] ||= ''
        @params['s.q'] ||= ''
        @params['s.fq'] ||= ''

        @params['s.role'] = options.delete('authorized') ? 'authenticated' : ''

        # process any Filter Query - turn Rails hash into array of
        # key:value pairs for feeding to the Summon API
        # (see inverse transform in SpectrumController#searchf)
        #  BEFORE: params[s.fq]={"AuthorCombined"=>"eric foner"}
        #  AFTER:  params[s.fq]="AuthorCombined:eric foner"
        if @params['s.fq'].kind_of?(Hash)
          new_fq = []
          @params['s.fq'].each_pair do |name, value|
            new_fq << "#{name}:#{value}" unless value.to_s.empty?
          end
          @params['s.fq'] = new_fq
        end

        @errors = nil
        begin
          # do_benchmarking = false
          # if do_benchmarking
          #   require 'summon/benchmark'
          #   bench = ::Summon::Benchmark.new()
          #   @config.merge!( :benchmark => bench)
          # end

          @service = ::Summon::Service.new(@config)

          Rails.logger.debug "[Spectrum][Summon] config: #{@config}"
          Rails.logger.debug "[Spectrum][Summon] params: #{@params}"

          ### THIS is the actual call to the Summon service to do the search
          @search = @service.search(@params)

          # if do_benchmarking
          #   bench.output
          # end


        rescue => e
          # We're getting 500 errors here - is that an internal server error
          # on the Summon side of things?  Need to look into this more.
          Rails.logger.error "#{self.class}##{__method__} error: #{e}"
          @errors = e.message
        end
      end


      FACET_ORDER = %w{ContentType_mfacet SubjectTerms_mfacet Language_s}

      def facets
        @search.facets.sort_by { |facet| (ind = FACET_ORDER.index(facet.field_name)) ? ind : 999 }
      end

      # The "pre-facet-options" are the four checkboxes which precede the facets.
      # Return array of ad-hoc structures, parsed by summon's facets partial
      def pre_facet_options_with_links()
        facet_options = []

        # first checkbox, "Full text online only"
        is_full_text = facet_value('IsFullText') == 'true'
        is_full_cmd = !is_full_text ? "addFacetValueFilters(IsFullText, true)" : "removeFacetValueFilter(IsFullText,true)"
        facet_options << {
          style: :checkbox,
          value: is_full_text,
          link: by_source_search_cmd(is_full_cmd),
          name: "Full text online only"
        }

        # second checkbox, "Scholarly publications only"
        is_scholarly = facet_value('IsScholarly') == 'true'
        is_scholarly_cmd = !is_scholarly ? "addFacetValueFilters(IsScholarly, true)" : "removeFacetValueFilter(IsScholarly,true)"
        facet_options << {
          style: :checkbox,
          value: is_scholarly,
          link: by_source_search_cmd(is_scholarly_cmd),
          name: "Scholarly publications only"
        }

        # third checkbox, "Exclude Newspaper Articles"
        exclude_newspapers = @search.query.facet_value_filters.any? { |fvf|
          fvf.field_name == "ContentType" &&
          fvf.value == "Newspaper Article" &&
          fvf.negated?
        }
        exclude_cmd = !exclude_newspapers ?
              "addFacetValueFilters(ContentType, Newspaper Article:t)" :
              "removeFacetValueFilter(ContentType, Newspaper Article)"
        facet_options << {
          style: :checkbox,
          value: exclude_newspapers,
          link: by_source_search_cmd(exclude_cmd),
          name: "Exclude Newspaper Articles"
        }

        # fourth checkbox, "Columbia's collection only"
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
        @search.query.facet_value_filters.any? { |fvf|
          fvf.field_name == "ContentType" &&
          fvf.value == "Newspaper Article" &&
          fvf.negated? }
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


      # The "constraints" are the displayed, cancelable, search params (queries, facets, etc.)
      # Return an array of ad-hoc structures, parsed by summon's constraints partial
      def constraints_with_links
        constraints = []
# raise
        # add in the basic search query
        @search.query.text_queries.each do |q|
          constraints << [q['textQuery'], by_source_search_cmd(q['removeCommand'])]
        end

        # add in "filter queries" - each advanced search field
        @search.query.text_filters.each do |q|
          filter_text = q['textFilter'].to_s.
              # strip "Combined" off the back of labels (TitleCombined --> Title)
              sub(/^([^\:]+)Combined:/,'\1:').
              # NEXT-581 - articles search by publication title
              # search for embedded capitals, insert a space (PublicationTitle --> Publication Title)
              sub(/([a-z])([A-Z])/,'\1 \2').
              sub(':', ': ')
          constraints << [filter_text, by_source_search_cmd(q['removeCommand'])]
        end

        # add in Facet limits
        @search.query.facet_value_filters.each do |fvf|
          unless fvf.field_name.titleize.in?("Is Scholarly", "Is Full Text")
            facet_text = "#{fvf.negated? ? "Not " : ""}#{fvf.field_name.titleize}: #{fvf.value}"
            constraints << [facet_text, by_source_search_cmd(fvf.remove_command)]
          end
        end

        # add in Range Filters
        @search.query.range_filters.each do |rf|
          facet_text = "#{rf.field_name.titleize}: #{rf.range.min_value}-#{rf.range.max_value}"
          constraints << [facet_text, by_source_search_cmd(rf.remove_command)]
        end

        constraints
      end


      # List of sort options, turned into a drop-down in summon's sorting/paging partial
      def sorts_with_links
        [
          [by_source_search_cmd('setSortByRelevancy()'), "Relevance"],
          [by_source_search_cmd('setSort(PublicationDate:desc)'), "Published Latest"],
          [by_source_search_cmd('setSort(PublicationDate:asc)'), "Published Earliest"]
        ]
      end


      # List of paging options, turned into a drop-down in summon's sorting/paging partial
      def page_size_with_links
        # [10,20,50,100].collect do |page_size|
        [10,25,50].collect do |page_size|
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
        # Why was this 20-page limit in effect?
        # total_pages > current_page && 20 > current_page

        # Summon API hard limit: only first 500 items will ever be returned.
        # Allow a next-page link if it's max item will be within this bound.
        page_size * (current_page + 1) <= 500
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
        # handle error condition when @search object is nil
        if @search
          @search.record_count
        else
          Rails.logger.error "[Spectrum][Summon] total_items called on null @search"
          0
        end
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


      # Create a link based on the current @search query, but
      # modified by whatever's passed in (facets, checkboxes, sort, paging),
      # and by possible advanced-search indicator
      def by_source_search_modify(cmd = {})
        # start with the query, directly extracted from the Summon object
        # (which means "s.fq=AuthorCombined:eric+foner")
        # Rails.logger.debug  "SQ=[#{@search.query.to_hash.inspect}]"
        params = @search.query.to_hash
        # NEXT-903 - ALWAYS reset to seeing page number 1.
        # The only exception is the Next/Prev page links, which will
        # reset s.pn via the passed input param cmd, below
        params.merge!( { 's.pn' => 1 } )
        # merge in whatever new command overlays current summon state
        params.merge!(cmd)
        # raise
        # add-in our CLIO interface-level params
        params.merge!( {'form' => @params['form']} ) if @params['form']
        params.merge!( {'search_field' => @search_field} ) if @search_field
        params.merge!( {'q' => @params['q']} ) if @params['q']
        # pass along the built-up params to a source-specific URL builder
        by_source_search_link(params)
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

