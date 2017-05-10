
module Spectrum
  module SearchEngines
    class Summon


      include ActionView::Helpers::NumberHelper
      include Rails.application.routes.url_helpers
      Rails.application.routes.default_url_options = ActionMailer::Base.default_url_options

      # These are ALWAYS in effect for Summon API queries
      # s.ff - how many options to retrieve for each filter field
      SUMMON_FIXED_PARAMS = {
        # 'spellcheck' => true,
        # # 's.ff' => ['ContentType,and,1,10', 'SubjectTerms,and,1,10', 'Language,and,1,5']
        # # Use helper function, to configure more flexibly
        # 's.ff' => summon_facets_to_params(get_summon_facets)
        # 
          # [
          # THESE DON'T SHOW UP
          # 'Audience,and,1,10',
          # 'Author,and,1,10',
          # 'CorporateAuthor,and,1,10',
          # 'Genre,and,1,10',
          # 'GeographicLocations,and,1,10',
          # 'Institution,and,1,10',
          # 'Library,and,1,10',
          # 'SourceType,and,1,10',
          # 'TemporalSubjectTerms,and,1,10'

          # THESE DO SHOW UP
          # 'SubjectTerms,and,1,10',
          # 'ContentType,and,1,10',
          # 'Language,and,1,10',
          # 'SourceName,and,1,10',
          # 'PublicationTitle,and,1,10',
          # 'Discipline,and,1,10',
          # 'DatabaseName,and,1,10',

          # These are IDs, not appropriate for patron display
          # 'SourcePackageID,and,1,10',
          # 'SourceID,and,1,10',
          # 'PackageID,and,1,10',

          # These we control via checkboxes, not facets
          # 'IsPeerReviewed,and,1,10',
          # 'IsScholarly,and,1,10',
          # ]

     }.freeze

      # These source-specific params are ONLY FOR NEW SEARCHES
      # s.ho=<boolean>     Holdings Only Parameter, a.k.a., "Columbia's collection only"
      SUMMON_DEFAULT_PARAMS = {

        'articles' =>  { 
          's.ho' => 't',
          # 's.cmd' => 'addFacetValueFilters(ContentType, Newspaper Article:t)'
          's.fvf' => ['ContentType, Newspaper Article,t']
        }.freeze,

        'summon_ebooks' => { 
          's.ho' => 't',
          's.cmd' => 'addFacetValueFilters(IsFullText, true)',
          's.fvf' => ['ContentType,eBook']
        }.freeze,

        'summon_dissertations' => {
          's.ho' => 't',
          's.fvf' => ['ContentType,Dissertation']
        }.freeze
      }.freeze

      attr_reader :source, :errors, :search
      attr_accessor :params

      # initialize() performs the actual API search, and
      # returns @search - a filled-in search structure, including query results.
      # input "options" are the CGI-param inputs, while
      # @params is a built-up parameters hash to pass to the Summon API
      def initialize(options = {}, summon_facets)
        # raise
        Rails.logger.debug "initialize() options=#{options.inspect}"
        @source = options.delete('source') || options.delete(:source) || options.delete('datasource') || options.delete(:datasource)
        @summon_facets = summon_facets

        @params = {}

        # These sources only come from bento-box aggregate searches, so enforce
        # the source-specific params without requires 'new_search' CGI param
        if @source && (@source == 'summon_ebooks' || @source == 'summon_dissertations')
          @params = SUMMON_DEFAULT_PARAMS[@source].dup

        # Otherwise, when source is Articles or Newspapers, we set source-specific default
        # params only for new searches.  Subsequent searches may change these values.
        elsif @source && options.delete('new_search')
          @params = SUMMON_DEFAULT_PARAMS[@source].dup
        end

        # These are ALWAYS in effect for Summon API queries
        # @params.merge!(SUMMON_FIXED_PARAMS)
        @params.merge!(summon_fixed_params)

        @config = options.delete('config') || APP_CONFIG['summon']

        @config.merge!(url: 'http://api.summon.serialssolutions.com/2.0.0')


        @config.symbolize_keys!

        @search_url = options.delete('search_url')

        @search_field = options.delete('search_field') || ''

        @debug_mode = options.delete('debug_mode') || false
        @debug_entries = Hash.arbitrary_depth

        # Map the 'q' CGI param to a 's.q' internal Summon param
        @params['s.q'] = options.delete('q')

        @params.merge!(options)
        @params.delete('utf8')

        # assure these are empty strings, if not passed via CGI params
        @params['s.q'] ||= ''
        @params['s.cmd'] ||= ''
        @params['s.fq'] ||= ''

        # This allows authenticated searches within Summon.
        #   http://api.summon.serialssolutions.com/help/api/search/parameters/role
        # It's set to 'authenticated' if we've logged in or are on-campus,
        # but that's done in SpectrumController, since this module
        # doesn't have access to necessary Application variables.
        @params['s.role'] ||= ''

        # process any Filter Query - turn Rails hash into array of
        # key:value pairs for feeding to the Summon API
        # (see inverse transform in SpectrumController#search)
        #  BEFORE: params[s.fq]={"AuthorCombined"=>"eric foner"}
        #  AFTER:  params[s.fq]="AuthorCombined:eric foner"
        if @params['s.fq'].kind_of?(Hash)
          new_fq = []
          @params['s.fq'].each_pair do |name, value|
            next if value.to_s.strip.empty?
            value = "(#{value})" unless value.starts_with? '('
            new_fq << "#{name}:#{value}" # unless value.to_s.empty?
          end
          @params['s.fq'] = new_fq
        end

        @errors = nil
# raise
        begin
          # This turns on a huge amount of logging, including
          # the full response JSON
          # @config.merge!(log: Rails.logger)

          Rails.logger.debug "[Spectrum][Summon] config: #{@config}"
          @service = ::Summon::Service.new(@config)

          ### THIS is the actual call to the Summon service to do the search
          start_time = Time.now
          @search = @service.search(@params)
          end_time = Time.now
          # May, 2017 - TODO - put these back to 'debug' after we've
          # spent a bit of time looking into Summon query performance.
          Rails.logger.warn "[Spectrum][Summon] params: #{@params}"
          Rails.logger.warn "[Spectrum][Summon] search took: #{(end_time - start_time).round(2)} sec"

          # if do_benchmarking
          #   bench.output
          # end

        rescue => ex
          # We're getting 500 errors here - is that an internal server error
          # on the Summon side of things?  Need to look into this more.
          Rails.logger.error "#{self.class}##{__method__} error: #{ex}"
          @errors = ex.message
        end
      end

      # FACET_ORDER = %w(ContentType SubjectTerms Language)

      def facets
        # raise
        # @search.facets.sort_by { |facet| (ind = Spectrum::SearchEngines::Summon.get_summon_facets.keys.index(facet.display_name)) ? ind : 999 }
        @search.facets.sort_by { |facet| (ind = @summon_facets.keys.index(facet.display_name)) ? ind : 999 }
      end

      # The "pre-facet-options" are the four checkboxes which precede the facets.
      # Return array of ad-hoc structures, parsed by summon's facets partial
      def pre_facet_options_with_links
        facet_options = []

        # first checkbox, "Full text online only"
        is_full_text = facet_value('IsFullText') == 'true'
        is_full_cmd = !is_full_text ? 'addFacetValueFilters(IsFullText, true)' : 'removeFacetValueFilter(IsFullText,true)'
        facet_options << {
          style: :checkbox,
          value: is_full_text,
          link: summon_search_cmd(is_full_cmd),
          name: 'Full text online only'
        }

        # second checkbox, "Scholarly publications only"
        is_scholarly = facet_value('IsScholarly') == 'true'
        is_scholarly_cmd = !is_scholarly ? 'addFacetValueFilters(IsScholarly, true)' : 'removeFacetValueFilter(IsScholarly,true)'
        facet_options << {
          style: :checkbox,
          value: is_scholarly,
          link: summon_search_cmd(is_scholarly_cmd),
          name: 'Scholarly publications only'
        }

        # third checkbox, "Exclude Newspaper Articles"
        exclude_newspapers = @search.query.facet_value_filters.any? do |fvf|
          fvf.field_name == 'ContentType' &&
          fvf.value == 'Newspaper Article' &&
          fvf.negated?
        end
        exclude_cmd = !exclude_newspapers ?
              'addFacetValueFilters(ContentType, Newspaper Article:t)' :
              'removeFacetValueFilter(ContentType, Newspaper Article)'
        facet_options << {
          style: :checkbox,
          value: exclude_newspapers,
          link: summon_search_cmd(exclude_cmd),
          name: 'Exclude Newspaper Articles'
        }

        # fourth checkbox, "Columbia's collection only"
        all_holdings_only = @search.query.holdings_only_enabled == true
        facet_options << {
          style: :checkbox,
          value: all_holdings_only,
          link: summon_search_cmd("setHoldingsOnly(#{!all_holdings_only})"),
          name: "Columbia's collection only"
        }

        facet_options
      end

      def search_path
        @search_url || summon_search_link(@params)
      end

      def current_sort_name
        if @search.query.sort.nil?
          'Relevance'
        elsif @search.query.sort.field_name == 'PublicationDate'
          if @search.query.sort.sort_order == 'desc'
            'Published Latest'
          else
            'Published Earliest'
          end
        end
      end

      # The "constraints" are the displayed, cancelable, search params
      # (currently applied queries, facets, etc.)
      # Return an array of ad-hoc structures, parsed by summon's constraints partial
      def constraints_with_links
        constraints = []
# raise
        # add in the basic search query
        @search.query.text_queries.each do |q|
          constraints << [q['textQuery'], summon_search_cmd(q['removeCommand'])]
        end

        # add in "filter queries" - each advanced search field
        @search.query.text_filters.each do |q|
          # This logic treated "Field:Value" as a single string.
          # Instead, let's split, treat each separately.
          # filter_text = q['textFilter'].to_s.
          #     # strip "Combined" off the back of labels (TitleCombined --> Title)
          #     sub(/^([^\:]+)Combined:/, '\1:').
          #     # NEXT-581 - articles search by publication title
          #     # search for embedded capitals, insert a space (PublicationTitle --> Publication Title)
          #     sub(/([a-z])([A-Z])/, '\1 \2').
          #     sub(':', ': ')
          # constraints << [filter_text, summon_search_cmd(q['removeCommand'])]
          displayField, displayValue = q['textFilter'].to_s.split(':')
          next unless displayField && displayValue
          displayField = displayField.
            # strip "Combined" off the back of labels (TitleCombined --> Title)
            sub(/^(.+)Combined$/, '\1').
            # NEXT-581 - articles search by publication title
            # search for embedded capitals, insert a space (PublicationTitle --> Publication Title)
            sub(/([a-z])([A-Z])/, '\1 \2')
          displayValue = displayValue.sub(/^\((.+)\)$/, '\1')
          constraints << ["#{displayField}: #{displayValue}", summon_search_cmd(q['removeCommand'])]
        end

        # add in Facet limits
        @search.query.facet_value_filters.each do |fvf|
          unless fvf.field_name.titleize.in?('Is Scholarly', 'Is Full Text')
            facet_text = "#{fvf.negated? ? "Not " : ""}#{fvf.field_name.titleize}: #{fvf.value}"
            constraints << [facet_text, summon_search_cmd(fvf.remove_command)]
          end
        end

        # add in Range Filters
        @search.query.range_filters.each do |rf|
          facet_text = "#{rf.field_name.titleize}: #{rf.range.min_value}-#{rf.range.max_value}"
          constraints << [facet_text, summon_search_cmd(rf.remove_command)]
        end

        constraints
      end

      # List of sort options, turned into a drop-down in summon's sorting/paging partial
      def sorts_with_links
        [
          [summon_search_cmd('setSortByRelevancy()'), 'Relevance'],
          [summon_search_cmd('setSort(PublicationDate:desc)'), 'Published Latest'],
          [summon_search_cmd('setSort(PublicationDate:asc)'), 'Published Earliest']
        ]
      end

      # List of paging options, turned into a drop-down in summon's sorting/paging partial
      def page_size_with_links
        # [10,20,50,100].collect do |page_size|
        [10, 25, 50].map do |per_page|
          # No, don't do a COMMAND...
          # [summon_search_cmd("setPageSize(#{page_size})"), page_size]
          # Just reset s.ps, it's much more transparent...
          [set_page_size(per_page), per_page]
        end
      end

      def successful?
        @errors.nil?
      end

      def documents
        @search.documents
      end

      # def start_over_link
      #   summon_search_link('new_search' => true)
      # end

      def previous_page?
        current_page > 1 && total_pages > 1
      end

      def previous_page_path
        set_page_path(current_page - 1)
      end

      def next_page?
        # Why was this 20-page limit in effect?
        # total_pages > current_page && 20 > current_page

        # # Summon API hard limit: only first 500 items will ever be returned.
        # # Allow a next-page link if it's max item will be within this bound.
        # page_size * (current_page + 1) <= 500

        # NEXT-1078 - CLIO Articles limit 500 records, Summon 1,000
        # Update - Maximum supported returned results set size is now 1000.
        page_size * (current_page + 1) <= 1000
      end

      def next_page_path
        set_page_path(current_page + 1)
      end

      def set_page_path(page_num)
        summon_search_modify('s.pn' => [total_pages, [page_num, 1].max].min)
      end

      def set_page_size(per_page)
        summon_search_modify('s.ps' => [(per_page || 10), 50].min)
      end

      def total_items
        # handle error condition when @search object is nil
        if @search
          @search.record_count
        else
          # I don't need to log this - I'm reliably logging the search failure which
          # led to this condition.
          # Rails.logger.error "[Spectrum][Summon] total_items called on null @search"
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
        @search.query.page_size.to_i
      end

      def summon_search_cmd(cmdText)
        summon_search_modify('s.cmd' => cmdText)
      end

      def summon_search_modify(extra_params = {})
        params = summon_params_modify(extra_params)
        # pass along the built-up params to a source-specific URL builder
        summon_search_link(params)
      end

      def summon_facet_cmd(cmdText)
      #   summon_facet_modify('s.cmd' => cmdText)
      # end
      # 
      # def summon_facet_modify(extra_params = {})
      #   params = summon_params_modify(extra_params)
        params = summon_params_modify('s.cmd' => cmdText)
        # pass along the built-up params to a source-specific URL builder
        summon_facet_link(params)
      end

      # Create a link based on the current @search query, but
      # modified by whatever's passed in (facets, checkboxes, sort, paging),
      # and by possible advanced-search indicator
      def summon_params_modify(extra_params = {})
        # start with the query, directly extracted from the Summon object
        # (which means "s.fq=AuthorCombined:eric+foner")
        # Rails.logger.debug  "SQ=[#{@search.query.to_hash.inspect}]"
        params = @search.query.to_hash
        # NEXT-903 - ALWAYS reset to seeing page number 1.
        # The only exception is the Next/Prev page links, which will
        # reset s.pn via the passed input param cmd, below
        params.merge!('s.pn' => 1)
        # Re-include page-size - this is sometimes dropped by the Summon API
        params.merge!('s.ps' => @search.query.page_size)
        # merge in whatever new command overlays current summon state
        params.merge!(extra_params)
        # raise
        # add-in our CLIO interface-level params
        params.merge!('form' => @params['form']) if @params['form']
        params.merge!('search_field' => @search_field) if @search_field
        params.merge!('q' => @params['q']) if @params['q']
        # # pass along the built-up params to a source-specific URL builder
        # summon_search_link(params)

        params
      end

      AVAILABLE_SUMMON_FACETS = [
        'SubjectTerms',
        'ContentType',
        'Language',
        'SourceName',
        'PublicationTitle',
        'Discipline',
        'DatabaseName',

        # These are IDs, not appropriate for patron display
        'SourcePackageID',
        'SourceID',
        'PackageID',

        # These we control via checkboxes, not facets
        'IsPeerReviewed',
        'IsScholarly',
      ]
      # DEFAULT_SUMMON_FACETS = {
      #   'ContentType' => 10, 'SubjectTerms' => 10, 'Language' => 10
      # }
      # # Application defaults
      # def self.get_system_summon_facets
      #   APP_CONFIG['summon_facets'] ||
      #   DEFAULT_SUMMON_FACETS ||
      #   []
      # end
      # # Application defaults with user overrides
      # def self.get_summon_facets
      #   # get_user_summon_facets() ||
      #   get_system_summon_facets() ||
      #   []
      # end


      private


      def facet_value(field_name)
        fvf = @search.query.facet_value_filters.find { |x| x.field_name == field_name }
        fvf ? fvf.value : nil
      end

      def summon_search_link(params = {})
        # These are ALWAYS in effect for Summon API queries
        # params.merge!(SUMMON_FIXED_PARAMS)
        params.merge!(summon_fixed_params)
        articles_index_path(params)
      end

      def summon_facet_link(params = {})
        articles_facet_path(params)
      end

      # SUMMON_FIXED_PARAMS = {
      #   'spellcheck' => true,
      #   # 's.ff' => ['ContentType,and,1,10', 'SubjectTerms,and,1,10', 'Language,and,1,5']
      #   # Use helper function, to configure more flexibly
      #   's.ff' => summon_facets_to_params(get_summon_facets)

      def summon_fixed_params
        {
          spellcheck: true,
          # undocumented - should help with incorrect facet values (database name)
          's.cache' => false,
          # 's.ff' => summon_facets_to_params(Spectrum::SearchEngines::Summon.get_summon_facets)
          's.ff' => summon_facets_to_params(@summon_facets)
        }
      end


      # { ContentType: 10, SubjectTerms: 10, Language: 10 }
      # to
      # ['ContentType,and,1,10', 'SubjectTerms,and,1,10', 'Language,and,1,5']
      def summon_facets_to_params(facets)
        facets.map { |facet_name, facet_count|
          "#{facet_name},and,1,#{facet_count}"
        }
      end



    end
  end
end
