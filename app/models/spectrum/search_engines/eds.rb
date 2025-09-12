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

      # The EDS API (gem 'ebsco-eds') knows the EDS facets by nicer names
      FACET_NAME_MAP = {
        'SourceType' =>  'eds_publication_type_facet',
        'SubjectEDS' =>  'eds_subject_topic_facet',
        'Language'   =>  'eds_language_facet'
      }
      FACET_LABEL_MAP = {
        'SourceType' =>  'Source Type',
        'SubjectEDS' =>  'Subject',
        'Language'   =>  'Language'
      }


      attr_reader :source, :errors, :search
#       attr_accessor :params

      # initialize() performs the actual API search, and
      # returns @search - a filled-in search structure, including query results.
      # input "options" are the CGI-param inputs
      def initialize(options = {}, eds_facets)
        # raise
        Rails.logger.debug "Spectrum::SearchEngines::Eds.initialize() options=#{options.inspect}"

        # fcd1, 07/29/25: FT1 limiter (Available in Library Collection)
        if  options['ft1'] == 'off'
          @ft1_limiter_on = false
        else
          @ft1_limiter_on = true
        end

        @source = options.fetch('datasource', nil)
        @q = options.delete('q')
        @errors = nil

        @eds_facets = eds_facets

        guest = true   # default
        guest = options.delete('guest') if options.has_key?('guest')

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
        # add additional options only when they're present.
        # some search keys exactly match params - some do not.
        # fcd1, 09/12/25: fix results per page
        # search_options['results_per_page'] = options['resultsperpage'] if options.key?('resultsperpage')
        search_options['results_per_page'] = options['results_per_page'] if options.key?('results_per_page')
        search_options['sort'] = options['sort'] if options.key?('sort')
        search_options['search_field'] = options['search_field'] if options.key?('search_field')
        search_options[:actions] = options['actions'] if options.key?('actions')

        if @source == 'articles_dissertations'
          search_options['f'] = {"eds_publication_type_facet"=>["Dissertations"]}
        elsif @source == 'articles_ebooks'
          search_options['f'] = {"eds_publication_type_facet"=>["eBooks"]}
        else
          search_options['f'] = options['f'] if options.key?('f')
        end

        @f = search_options['f']

        ## ## ## DEBUG ## ## ## 
        ####  Speaking EDS API - does not work
        # search_options['limiter'] =  'DT1:1920-01/1940-01'
        # GET http://eds-api.ebscohost.com/edsapi/rest/search?query=boston&includefacets=y&
        # limiter=DT1:1980-01%2f2015-12
        ####  Speaking Blacklight - works
        # blacklight year range slider input
        # "range"=>{"pub_year_tisim"=>{"begin"=>"1970", "end"=>"1980"}}
        # search_options["range"] = {"pub_year_tisim"=>{"begin"=>"1970", "end"=>"1980"}}
      
        # All I have to do here is send it along to the gem library if it's in the URL
        search_options['range'] = options['range'] if options.key?('range')

        # fcd1, 09/10/25: Add FT1 limiter
        search_options[:limiters] = ['FT1:Y'] if @ft1_limiter_on

        @search = eds_session.search(search_options)
        
        begin
          Rails.logger.debug "[Spectrum][Eds] search_options: #{search_options}"
          start_time = Time.now
          @search = eds_session.search(search_options)
          Rails.logger.debug(  @search.inspect  )

          end_time = Time.now
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
# >> @search.applied_facets
# => [{"FacetValue"=>{"Id"=>"Language", "Value"=>"spanish"}, "RemoveAction"=>"removefacetfiltervalue(1,Language:spanish)"}]
# 

      # The facets that we want to show are in @eds_facets (populated from app_config).
      # We need to collect facet-values for each of these facets, pulled out of the
      # search results (@search), from both @search.applied_facets and @search.facets
      def facets
        facets = []

        # loop over our configured list of facets
        @eds_facets.each do |configured_facet|
          configured_facet_id, configured_facet_count = configured_facet
          
          # Create a facet structure...
          facet = { id: configured_facet_id, label: '', values: [], applied_values: [] }
          
          # If we have any applied facet-value filter for THIS facet, 
          # add that value, first, to the facet (with the "remove" action)
          @search.applied_facets.to_a.each do |applied_facet|
            id     = applied_facet['FacetValue']['Id']
            value  = applied_facet['FacetValue']['Value']
            action = applied_facet['RemoveAction']
            if id == configured_facet_id
              applied_facet_filter_value = { 
                value:     value,
                hitcount:  @search.stat_total_hits,
                action:    action
              }
              facet[:applied_values] << applied_facet_filter_value
            end
          end

          # raise if configured_facet_id == 'Language'   # DEBUG

          # locate the configured facet in the full list of search-results facets
          @search.facets.each do |search_results_facet|
            # We've found the facet - now trim the value list to show only the first N values
            if search_results_facet[:id] == configured_facet_id
              # Use EDS internal "label" field, or use a local configuration?
              # These are initially identical - but we might modify our local labels.
              # facet[:label] = search_results_facet[:label]
              facet[:label] = FACET_LABEL_MAP[configured_facet_id]
              
              
              count_so_far = facet[:values].size
              count_needed = configured_facet_count - count_so_far
              # concatenate an array on the end of another array
              facet[:values] += search_results_facet[:values].first(count_needed)
            end
          end
          
          facets << facet
          
        end
        return facets
          
        # @search.facets.sort_by { |facet| (ind = Spectrum::SearchEngines::Summon.get_summon_facets.keys.index(facet.display_name)) ? ind : 999 }
      end


      # THIS WORKS:
      # http://cliobeta.columbia.edu:3001/articles?q=smith&f[eds_language_facet][]=French
      #
      # THIS WORKS:
      # http://cliobeta.columbia.edu:3001/articles?q=smith&f[eds_language_facet][]=French&f[eds_language_facet][]=Spanish
      # 2025-04-01 18:24:02 [DEBUG] ===========================  OPTIONS  {:query=>"smith", "page"=>1, "f"=>{"eds_language_facet"=>["French", "Spanish"]}}
      # 2025-04-01 18:24:04 [DEBUG] [Spectrum][Eds] search_options: {:query=>"smith", "page"=>1, "f"=>{"eds_language_facet"=>["French", "Spanish"]}}

      
      def eds_add_facet_filter(facet_id, facet_value)
        facet_name = FACET_NAME_MAP[facet_id]
        facet_param = { "f[#{facet_name}][]": facet_value }

        return eds_search_modify( facet_param )
      end

      # fcd1, 07/29/25: Updated method for EDS
      # for now, just FT1 (Available in Library Collection) limiter
      def pre_facet_options_with_links
        facet_options = []

        # FT1 (Available in Library Collection) limiter. Checkbox toggles limiter on-off
        facet_options << {
          style: :checkbox,
          value: @ft1_limiter_on,
          link_suffix: @ft1_limiter_on ? '&ft1=off' : '&ft1=on',
          name: "Columbia's collection only"
        }

        facet_options
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
          'q' => @q,
          'f' => @f
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
        
        @search.applied_facets.each do |applied_facet|
          id     = applied_facet['FacetValue']['Id']
          value  = applied_facet['FacetValue']['Value']
          remove_action = applied_facet['RemoveAction']
          query_text = "#{FACET_LABEL_MAP[id]}: #{value.humanize}"
          remove_link = eds_search_modify('actions' => remove_action)
          constraints << [query_text, remove_link]
        end
        
        # The only limiter we support currently is a date-limiter, 
        # which lets us take some shortcuts here
        # @search.applied_limiters.each do |applied_limiter|
        # end
        date_range = date_limit_to_date_range(@search.applied_limiters)
        if date_range
          query_text = "Publication Date: #{date_range["begin_year"]} to #{date_range["end_year"]}"
          remove_link = eds_search_modify('actions' => date_range["remove_action"])
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
        # fcd1, 09/12/25: fix results per page
        # eds_search_modify('resultsperpage' => [(per_page || 10), 50].min)
        eds_search_modify('results_per_page' => [(per_page || 10), 50].min)
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

        # Parameter used to enable/disable FT1 Limiter
        params[:ft1] = @ft1_limiter_on ? 'on' : 'off'

        # don't persist the "actions" params that landed on this page
        params.delete(:actions)
        
        # We need to drop any "f" facet filters that are in the 
        # URL - because they may be the target of a RemoveAction.
        # Instead, rebuild "f" from @search.applied_filters
        params.delete('f')
        @search.applied_facets.each do |applied_facet|
          # { "FacetValue"   => { "Id" => "Language", "Value" => "spanish" },
          #   "RemoveAction" => "removefacetfiltervalue(1,Language:spanish)" }
          facet_id    = applied_facet["FacetValue"]["Id"]
          facet_value = applied_facet["FacetValue"]["Value"]
          facet_name = FACET_NAME_MAP[facet_id]
          # careful - the value of this params key needs to be an array...
          # params["f[#{facet_name}][]"] ||= []
          # params["f[#{facet_name}][]"] << facet_value
          params["f[#{facet_name}]"] ||= []
          params["f[#{facet_name}]"] << facet_value
        end
        
        # Same logic - remove the date-range, because it may have been 
        # nullified by an Action.  Then re-add a date range, based on 
        # applied_limiters - which shows actual in-effect limits
        params.delete('range')
        @search.applied_limiters.each do |applied_limit|
          limit_id = applied_limit["Id"]
          if limit_id.starts_with?('DT')
            date_range = date_limit_to_date_range(@search.applied_limiters)
            if date_range
              params["range"] = { "pub_year_tisim": 
                                  { "begin": date_range["begin_year"], 
                                      "end": date_range["end_year"]   } }
            end
          end
        end
        
         # raise if extra_params.to_s.match(/creole/)
        
        
# Rails.logger.debug "=== RAW === " + search.raw_options.to_s

#  FACETS
# they will be in the params as an action:
# >> @search.raw_options
# => {:query=>"smith", "page"=>1, "search_field"=>"q", :actions=>"addfacetfilter(Language:spanish)"}

# We need to rewrite these as a facet param:
#  f: { eds_language_facet: [spanish, french]}

# Or rewrite like this:
# facetfilter=1,Language:english
# facetfilter=2,Language:french
# 
#  (But not as an ongoing series of actions!)
# 
# >> @search.raw_options
# => {:query=>"smith", "page"=>1, "search_field"=>"q", :actions=>"addfacetfilter(Language:spanish)"}
# >> @search.applied_facets
# => [{"FacetValue"=>{"Id"=>"Language", "Value"=>"spanish"}, "RemoveAction"=>"removefacetfiltervalue(1,Language:spanish)"}]
# >> @search.facets.first[:values].first
# => {:value=>"Academic Journals", :hitcount=>75333, :action=>"addfacetfilter(SourceType:Academic Journals)"}
# 

        # NEXT-903 - ALWAYS reset to seeing page number 1.
        params.delete('page')

        # Does "raw_options" include everything we need?
        # params['q'] = @q
        # params['sort'] = @search.search_criteria['Sort'] unless @search.search_criteria['Sort'].eql?('relevance')
        # params['resultsperpage'] = @search.retrieval_criteria['ResultsPerPage']

        # # Move query term from "query" to "q" to make CLIO work!
        params['q'] = params.delete(:query)
        
        # No - this merge will overwrite "f" facet-filters
        # params.merge!(extra_params)
        # Instead do this - if key exists as array, append new value
        extra_params.each do |key, value|
          if params.key?(key) and params[key].is_a?(Array)
            # If the key already exists and its value is an array, append the new values
            params[key] += Array(value)  # Ensure 'value' is treated as an array (in case it's not)
          else
            # Otherwise, just use the new key/value pair from "extra_params"
            params[key] = value
          end
        end

        params
      end
      
      
      # - Given an EDS date-limit in format:
      # { "Id"=>"DT1", 
      #   "LimiterValuesWithAction" => [
      #       { "Value" => "1970-01/1980-01", 
      #         "RemoveAction"=>"removelimitervalue(DT1:1970-01/1980-01)" }
      #   ],
      #   "RemoveAction" => "removelimiter(DT1)"
      # }
      # Return a simple two-element array of year strings:
      #   [ "1970", "1980" ]
      def date_limit_to_date_range(applied_limiters)
        return nil unless applied_limiters and applied_limiters.is_a?(Array)

        applied_limiters.each do |applied_limit|
          return nil unless applied_limit.is_a?(Hash) and applied_limit.has_key?("Id") and applied_limit["Id"] == 'DT1'

          remove_action = applied_limit["RemoveAction"]

          applied_limit['LimiterValuesWithAction'].each do |value_with_action|
            # "Value"=>"1970-01/1980-01"
            value = value_with_action["Value"]
            # Look for 4-digit substrings
            year_substrings = value.scan(/\b\d{4}\b/)
            # Fail unless we found exactly two 4-digit strings
            return nil unless year_substrings.length == 2
            # Return the data...
            date_range = {
              "begin_year"     => year_substrings[0],
              "end_year"       => year_substrings[1],
              "remove_action"  => remove_action,
            }
            return date_range
          end
        end

        # if we didn't manage to find a begin & end date range, return nil
        return nil
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



#  DATE RANGE - INFORMATION
# >> @search.applied_limiters
# => [{"Id"=>"DT1", "LimiterValuesWithAction"=>[{"Value"=>"1970-01/1980-01", "RemoveAction"=>"removelimitervalue(DT1:1970-01/1980-01)"}], "RemoveAction"=>"removelimiter(DT1)"}]
# >> l1 = @search.applied_limiters.first
# => {"Id"=>"DT1", "LimiterValuesWithAction"=>[{"Value"=>"1970-01/1980-01", "RemoveAction"=>"removelimitervalue(DT1:1970-01/1980-01)"}], "RemoveAction"=>"removelimiter(DT1)"}
# >> l1.keys
# => ["Id", "LimiterValuesWithAction", "RemoveAction"]
# >> l1['LimiterValuesWithAction']['Value']
# !! #<TypeError: no implicit conversion of String into Integer>
# >> l1['LimiterValuesWithAction'].keys
# !! #<NoMethodError: undefined method `keys' for #<Array:0x00007fa7407969d8>>
# >> l1['LimiterValuesWithAction']
# => [{"Value"=>"1970-01/1980-01", "RemoveAction"=>"removelimitervalue(DT1:1970-01/1980-01)"}]
# >> lv1 = l1['LimiterValuesWithAction'].first
# => {"Value"=>"1970-01/1980-01", "RemoveAction"=>"removelimitervalue(DT1:1970-01/1980-01)"}
# >> lv1
# => {"Value"=>"1970-01/1980-01", "RemoveAction"=>"removelimitervalue(DT1:1970-01/1980-01)"}
# >> lv1['Value']
# => "1970-01/1980-01"
# >>
#
# >> @search.raw_options
# => {:query=>"dogs", "page"=>1, "search_field"=>"q", "range"=>{"pub_year_tisim"=>{"begin"=>"1970", "end"=>"1980"}}}
# ####  Speaking EDS API - does not work
# # search_options['limiter'] =  'DT1:1920-01/1940-01'
# # GET http://eds-api.ebscohost.com/edsapi/rest/search?query=boston&includefacets=y&
# # limiter=DT1:1980-01%2f2015-12
# ####  Speaking Blacklight - works
# # blacklight year range slider input
# # "range"=>{"pub_year_tisim"=>{"begin"=>"1970", "end"=>"1980"}}
# search_options["range"] = {"pub_year_tisim"=>{"begin"=>"1970", "end"=>"1980"}}
# 



    end

  end

end



