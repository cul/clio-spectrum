# FOLIO-133 - Build Articles+ Bento for EDS
#
# Links to useful docs and code:
#
# https://developer.ebsco.com/eds-api/docs/introduction
#
# https://developer.ebsco.com/eds-api/docs/blacklight
#
# We use this one:
#   https://github.com/ebsco/edsapi-ruby
#
# There are also....
#   https://github.com/ebsco/blacklight_eds_gem
#   https://github.com/ebsco/ebsco-discovery-service-api-gem
#




module Spectrum
  module SearchEngines
    class Eds

#       include ActionView::Helpers::NumberHelper

      include Rails.application.routes.url_helpers

      attr_reader :source, :errors, :search
#       attr_accessor :params

      # initialize() performs the actual API search, and
      # returns @search - a filled-in search structure, including query results.
      # input "options" are the CGI-param inputs
      def initialize(options = {}, eds_facets)
        # raise
        Rails.logger.debug "Spectrum::SearchEngines::Eds.initialize() options=#{options.inspect}"

        @q = options.delete('q')
        @errors = nil

        @eds_facets = eds_facets

        guest = true   # default
        guest = options.delete('guest') if options.has_key?('guest')

        begin
          eds_config = APP_CONFIG['eds']
          session_params = {
            user:    eds_config['username'],
            pass:    eds_config['password'],
            profile: eds_config['profile_id'],
            guest:   guest
          }
          eds_session = EBSCO::EDS::Session.new(session_params)

          # Something's funky here.  
          #   :query needs to be a symbol,
          #   "page" needs to be a string
          # Options processing logic (edsapi-ruby options.rb) is very inconsistent 
          # with regard to the key values (string v.s. symbol, lower-case v.s. snake-case, etc.)
          search_options = {
            query:  @q,
            "page" =>  options['pagenumber'] || 1
          }
          # add additional options only when they're present
          search_options['results_per_page'] = options['resultsperpage'] if options.key?('resultsperpage')
          search_options['sort'] = options['sort'] if options.key?('sort')
          search_options['search_field'] = options['search_field'] if options.key?('search_field')
          search_options[:actions] = options['actions'] if options.key?('actions')

          start_time = Time.now
          @search = eds_session.search(search_options)
          end_time = Time.now
          Rails.logger.debug "[Spectrum][Eds] search_options: #{search_options}"
          Rails.logger.debug "[Spectrum][Eds] search took: #{(end_time - start_time).round(2)} sec"

        rescue => ex
          # We're getting 500 errors here - is that an internal server error
          # on the Summon side of things?  Need to look into this more.
          Rails.logger.error "#{self.class}##{__method__} error: #{ex}"
          @errors = ex.message
        end
        
        # raise

      end
      



#       # FACET_ORDER = %w(ContentType SubjectTerms Language)
#
      def facets
        facets = []
        # loop over our configured list of facets to show...
        @eds_facets.keys.each do |configured_facet_id|
          # locate the configured facet in the full list of facets
          # returned by the EDS search
          @search.facets.each do |search_results_facet|
            facets << search_results_facet if search_results_facet[:id] == configured_facet_id
          end
        end
        return facets
          
        # @search.facets.sort_by { |facet| (ind = Spectrum::SearchEngines::Summon.get_summon_facets.keys.index(facet.display_name)) ? ind : 999 }
      end

#       # The "pre-facet-options" are the four checkboxes which precede the facets.
#       # Return array of ad-hoc structures, parsed by summon's facets partial
#       def pre_facet_options_with_links
#         facet_options = []
#
#         # first checkbox, "Full text online only"
#         is_full_text = facet_value('IsFullText') == 'true'
#         is_full_cmd = !is_full_text ? 'addFacetValueFilters(IsFullText, true)' : 'removeFacetValueFilter(IsFullText,true)'
#         facet_options << {
#           style: :checkbox,
#           value: is_full_text,
#           link: summon_search_cmd(is_full_cmd),
#           name: 'Full text online only'
#         }
#
#         # second checkbox, "Scholarly publications only"
#         is_scholarly = facet_value('IsScholarly') == 'true'
#         is_scholarly_cmd = !is_scholarly ? 'addFacetValueFilters(IsScholarly, true)' : 'removeFacetValueFilter(IsScholarly,true)'
#         facet_options << {
#           style: :checkbox,
#           value: is_scholarly,
#           link: summon_search_cmd(is_scholarly_cmd),
#           name: 'Scholarly publications only'
#         }
#
#         # third checkbox, "Exclude Newspaper Articles"
#         exclude_newspapers = @search.query.facet_value_filters.any? do |fvf|
#           fvf.field_name == 'ContentType' &&
#             fvf.value == 'Newspaper Article' &&
#             fvf.negated?
#         end
#         exclude_cmd = !exclude_newspapers ?
#               'addFacetValueFilters(ContentType, Newspaper Article:t)' :
#               'removeFacetValueFilter(ContentType, Newspaper Article)'
#         facet_options << {
#           style: :checkbox,
#           value: exclude_newspapers,
#           link: summon_search_cmd(exclude_cmd),
#           name: 'Exclude Newspaper Articles'
#         }
#
#         # fourth checkbox, "Columbia's collection only"
#         all_holdings_only = @search.query.holdings_only_enabled == true
#         facet_options << {
#           style: :checkbox,
#           value: all_holdings_only,
#           link: summon_search_cmd("setHoldingsOnly(#{!all_holdings_only})"),
#           name: "Columbia's collection only"
#         }
#
#         facet_options
#       end

      def search_path
        # try just this - elaborate if we need to
        params = {
          'q' => @q
        }
        articles_index_path(params)
        
        # Summon had these:
        # @search_url || summon_search_link(@params)
        #
        # @search_url = options.delete('search_url')
        #
        # def summon_search_link(params = {})
        #   # These are ALWAYS in effect for Summon API queries
        #   # params.merge!(SUMMON_FIXED_PARAMS)
        #   params.merge!(summon_fixed_params)
        #   articles_index_path(params)
        # end
        
      end

      # GET {{edsUrl}}/edsapi/rest/info
      # ...
      #     <AvailableSorts>
      #         <AvailableSort>
      #             <Id>relevance</Id>
      #             <Label>Relevance</Label>
      #             <AddAction>setsort(relevance)</AddAction>
      #         </AvailableSort>
      #         <AvailableSort>
      #             <Id>date</Id>
      #             <Label>Date Newest</Label>
      #             <AddAction>setsort(date)</AddAction>
      #         </AvailableSort>
      #         <AvailableSort>
      #             <Id>date2</Id>
      #             <Label>Date Oldest</Label>
      #             <AddAction>setsort(date2)</AddAction>
      #         </AvailableSort>
      #     </AvailableSorts>
      # ...
      def current_sort_name
        # works...
        # current_sort = @search.results['SearchRequest']['SearchCriteria']['Sort']
        # shortcut in edsapi-ruby results.rb
        current_sort = @search.search_criteria['Sort']

        return 'Date Newest' if current_sort.eql?('date')
        return 'Date Oldest' if current_sort.eql?('date2')

        # if current-sort is either 'relevance' or undefined
        return 'Relevance'
      end

      # The "constraints" are the displayed, cancelable, search params
      # (currently applied queries, facets, etc.)
      # Return an array of ad-hoc structures, parsed by eds's constraints partial
      def constraints_with_links
        constraints = []
        
        all_queries_with_actions = @search.search_criteria_with_actions['QueriesWithAction'].to_a
        all_queries_with_actions.each do |query_with_action|
          query_text  = query_with_action['Query']['Term']
          if query_with_action['Query'].key?('FieldCode')
            query_text = query_with_action['Query']['FieldCode'] + ':' + query_text
          end
          remove_action = query_with_action['RemoveAction']
          remove_link = eds_search_modify('actions' => remove_action)

          constraints << [query_text, remove_link]
        end
        
        constraints
      end

      # List of sort options, turned into a drop-down in summon's sorting/paging partial
      def sorts_with_links
        # [
        #   [summon_search_cmd('setsort(relevance)'), 'Relevance'],
        #   [summon_search_cmd('setsort(date)'),      'Date Newest'],
        #   [summon_search_cmd('setsort(date2)'),     'Date Oldest'],
        # ]
        [
          [ eds_search_modify( { 'sort' => 'relevance'} ), 'Relevance'],
          [ eds_search_modify( { 'sort' => 'date'} ),      'Date Newest'],
          [ eds_search_modify( { 'sort' => 'date2'} ),     'Date Oldest'],
        ]
      end

      # List of paging options, turned into a drop-down in eds's sorting/paging partial
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
        @search.records
      end

#       # def start_over_link
#       #   summon_search_link('new_search' => true)
#       # end

      def previous_page?
        current_page > 1 && total_pages > 1
      end

      def previous_page_path
        set_page_path(current_page - 1)
      end

      def next_page?
        page_size * (current_page + 1) <= 1000
      end

      def next_page_path
        set_page_path(current_page + 1)
      end

      def set_page_path(page_num)
        eds_search_modify('pagenumber' => page_num)
      end

      def set_page_size(per_page)
        eds_search_modify('resultsperpage' => [(per_page || 10), 50].min)
      end

      def total_items
        # handle error condition when @search object is nil
        if @search
          @search.stat_total_hits()
        else
          # Don't need to log this - we're logging the search failure which led to this.
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
         total_hits = @search.stat_total_hits
         total_page = (total_hits / page_size).to_i
       end

      def current_page
        @search.page_number()
      end

      def page_size
        retrieval_criteria = @search.retrieval_criteria()
        return retrieval_criteria['ResultsPerPage']
      end

      def eds_search_action(action)
        eds_search_modify('actions' => action)
      end

      def eds_search_modify(extra_params = {})
        params = eds_params_modify(extra_params)
        articles_index_path(params)
      end

#       def summon_facet_cmd(cmdText)
#         #   summon_facet_modify('s.cmd' => cmdText)
#         # end
#         #
#         # def summon_facet_modify(extra_params = {})
#         #   params = summon_params_modify(extra_params)
#         params = summon_params_modify('s.cmd' => cmdText)
#         # pass along the built-up params to a source-specific URL builder
#         summon_facet_link(params)
#       end



# >> @search.retrieval_criteria
# => {"View"=>"brief", "ResultsPerPage"=>25, "PageNumber"=>1, "Highlight"=>"y", "IncludeImageQuickView"=>"false"}
#
# >> @search.search_criteria
# => {"Queries"=>[{"BooleanOperator"=>"AND", "Term"=>"smith"}], "SearchMode"=>"all", "IncludeFacets"=>"y", "Expanders"=>["fulltext", "relatedsubjects"], "Sort"=>"relevance", "RelatedContent"=>["emp"], "AutoSuggest"=>"y", "AutoCorrect"=>"n"}
#
      # Create a link based on the current @search query, but
      # modified by whatever's passed in (facets, checkboxes, sort, paging),
      # and by possible advanced-search indicator
      def eds_params_modify(extra_params = {})
        params = @search.raw_options.dup
# Rails.logger.debug "=== RAW === " + search.raw_options.to_s

        # NEXT-903 - ALWAYS reset to seeing page number 1.
        params.delete('page')

        # Does "raw_options" include everything we need?
        # params['q'] = @q
        # params['sort'] = @search.search_criteria['Sort'] unless @search.search_criteria['Sort'].eql?('relevance')
        # params['resultsperpage'] = @search.retrieval_criteria['ResultsPerPage']

        # # Move query term from "query" to "q" to make CLIO work!
        params['q'] = params.delete(:query)
        
        params.merge!(extra_params)

        params
      end

#       AVAILABLE_SUMMON_FACETS = [
#         'SubjectTerms',
#         'ContentType',
#         'Language',
#         'SourceName',
#         'PublicationTitle',
#         'Discipline',
#         'DatabaseName',
#
#         # These are IDs, not appropriate for patron display
#         'SourcePackageID',
#         'SourceID',
#         'PackageID',
#
#         # These we control via checkboxes, not facets
#         'IsPeerReviewed',
#         'IsScholarly'
#       ].freeze
#       # DEFAULT_SUMMON_FACETS = {
#       #   'ContentType' => 10, 'SubjectTerms' => 10, 'Language' => 10
#       # }
#       # # Application defaults
#       # def self.get_system_summon_facets
#       #   APP_CONFIG['summon_facets'] ||
#       #   DEFAULT_SUMMON_FACETS ||
#       #   []
#       # end
#       # # Application defaults with user overrides
#       # def self.get_summon_facets
#       #   # get_user_summon_facets() ||
#       #   get_system_summon_facets() ||
#       #   []
#       # end
#
#       private
#
#       def facet_value(field_name)
#         fvf = @search.query.facet_value_filters.find { |x| x.field_name == field_name }
#         fvf ? fvf.value : nil
#       end
#
#       def summon_search_link(params = {})
#         # These are ALWAYS in effect for Summon API queries
#         # params.merge!(SUMMON_FIXED_PARAMS)
#         params.merge!(summon_fixed_params)
#         articles_index_path(params)
#       end
#
#       def summon_facet_link(params = {})
#         articles_facet_path(params)
#       end
#
#       # SUMMON_FIXED_PARAMS = {
#       #   'spellcheck' => true,
#       #   # 's.ff' => ['ContentType,and,1,10', 'SubjectTerms,and,1,10', 'Language,and,1,5']
#       #   # Use helper function, to configure more flexibly
#       #   's.ff' => summon_facets_to_params(get_summon_facets)
#
#       def summon_fixed_params
#         {
#           spellcheck: true,
#           # undocumented - should help with incorrect facet values (database name)
#           's.cache' => false,
#           # 's.ff' => summon_facets_to_params(Spectrum::SearchEngines::Summon.get_summon_facets)
#           's.ff' => summon_facets_to_params(@summon_facets)
#         }
#       end
#
#       # { ContentType: 10, SubjectTerms: 10, Language: 10 }
#       # to
#       # ['ContentType,and,1,10', 'SubjectTerms,and,1,10', 'Language,and,1,5']
#       def summon_facets_to_params(facets)
#         facets.map do |facet_name, facet_count|
#           "#{facet_name},and,1,#{facet_count}"
#         end
#       end
    end
  end
end
