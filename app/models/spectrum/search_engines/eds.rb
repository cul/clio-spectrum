
module Spectrum
  module SearchEngines
    class Eds

#       include ActionView::Helpers::NumberHelper

      include Rails.application.routes.url_helpers

#       Rails.application.routes.default_url_options = ActionMailer::Base.default_url_options
#
#       # These are ALWAYS in effect for Summon API queries
#       # s.ff - how many options to retrieve for each filter field
#       SUMMON_FIXED_PARAMS = {
#         # 'spellcheck' => true,
#         # # 's.ff' => ['ContentType,and,1,10', 'SubjectTerms,and,1,10', 'Language,and,1,5']
#         # # Use helper function, to configure more flexibly
#         # 's.ff' => summon_facets_to_params(get_summon_facets)
#         #
#         # [
#         # THESE DON'T SHOW UP
#         # 'Audience,and,1,10',
#         # 'Author,and,1,10',
#         # 'CorporateAuthor,and,1,10',
#         # 'Genre,and,1,10',
#         # 'GeographicLocations,and,1,10',
#         # 'Institution,and,1,10',
#         # 'Library,and,1,10',
#         # 'SourceType,and,1,10',
#         # 'TemporalSubjectTerms,and,1,10'
#
#         # THESE DO SHOW UP
#         # 'SubjectTerms,and,1,10',
#         # 'ContentType,and,1,10',
#         # 'Language,and,1,10',
#         # 'SourceName,and,1,10',
#         # 'PublicationTitle,and,1,10',
#         # 'Discipline,and,1,10',
#         # 'DatabaseName,and,1,10',
#
#         # These are IDs, not appropriate for patron display
#         # 'SourcePackageID,and,1,10',
#         # 'SourceID,and,1,10',
#         # 'PackageID,and,1,10',
#
#         # These we control via checkboxes, not facets
#         # 'IsPeerReviewed,and,1,10',
#         # 'IsScholarly,and,1,10',
#         # ]
#       }.freeze


      attr_reader :source, :errors, :search
#       attr_accessor :params


      # initialize() performs the actual API search, and
      # returns @search - a filled-in search structure, including query results.
      # input "options" are the CGI-param inputs
      def initialize(options = {})
        # raise
        Rails.logger.debug "Spectrum::SearchEngines::Eds.initialize() options=#{options.inspect}"

        @q = options.delete('q')
        @errors = nil

        begin
          eds_config = APP_CONFIG['eds']
          eds_params = {
            user:    eds_config['username'],
            pass:    eds_config['password'],
            profile: eds_config['profile_id'],
          }

          eds_session = EBSCO::EDS::Session.new(eds_params)

          start_time = Time.now
          @search = eds_session.simple_search(@q)
          end_time = Time.now
          Rails.logger.debug "[Spectrum][Eds] params: #{@q}"
          Rails.logger.debug "[Spectrum][Eds] search took: #{(end_time - start_time).round(2)} sec"

        rescue => ex
          # We're getting 500 errors here - is that an internal server error
          # on the Summon side of things?  Need to look into this more.
          Rails.logger.error "#{self.class}##{__method__} error: #{ex}"
          @errors = ex.message
        end
      end
      



#       # FACET_ORDER = %w(ContentType SubjectTerms Language)
#
#       def facets
#         # raise
#         # @search.facets.sort_by { |facet| (ind = Spectrum::SearchEngines::Summon.get_summon_facets.keys.index(facet.display_name)) ? ind : 999 }
#         @search.facets.sort_by { |facet| (ind = @summon_facets.keys.index(facet.display_name)) ? ind : 999 }
#       end
#
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
#
#       def search_path
#         @search_url || summon_search_link(@params)
#       end
#
#       def current_sort_name
#         if @search.query.sort.nil?
#           'Relevance'
#         elsif @search.query.sort.field_name == 'PublicationDate'
#           if @search.query.sort.sort_order == 'desc'
#             'Published Latest'
#           else
#             'Published Earliest'
#           end
#         end
#       end

      # The "constraints" are the displayed, cancelable, search params
      # (currently applied queries, facets, etc.)
      # Return an array of ad-hoc structures, parsed by eds's constraints partial
      def constraints_with_links
        constraints = []

        # Add the basic query term, possibly fielded.
        query = @q.dup
        constraints << [query, eds_index_path]

        constraints
      end

#       # List of sort options, turned into a drop-down in summon's sorting/paging partial
#       def sorts_with_links
#         [
#           [summon_search_cmd('setSortByRelevancy()'), 'Relevance'],
#           [summon_search_cmd('setSort(PublicationDate:desc)'), 'Published Latest'],
#           [summon_search_cmd('setSort(PublicationDate:asc)'), 'Published Earliest']
#         ]
#       end
#
#       # List of paging options, turned into a drop-down in summon's sorting/paging partial
#       def page_size_with_links
#         # [10,20,50,100].collect do |page_size|
#         [10, 25, 50].map do |per_page|
#           # No, don't do a COMMAND...
#           # [summon_search_cmd("setPageSize(#{page_size})"), page_size]
#           # Just reset s.ps, it's much more transparent...
#           [set_page_size(per_page), per_page]
#         end
#       end

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

#       def previous_page_path
#         set_page_path(current_page - 1)
#       end

      def next_page?
        page_size * (current_page + 1) <= 1000
      end

      def next_page_path
        set_page_path(current_page + 1)
      end

      def set_page_path(page_num)
        eds_search_modify('pagenumber' => page_num)
      end

#       def set_page_size(per_page)
#         summon_search_modify('s.ps' => [(per_page || 10), 50].min)
#       end

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

#       def total_pages
#         @search.page_count
#       end

      def current_page
        @search.page_number()
      end

      def page_size
        retrieval_criteria = @search.retrieval_criteria()
        return retrieval_criteria['ResultsPerPage']
      end

#       def summon_search_cmd(cmdText)
#         summon_search_modify('s.cmd' => cmdText)
#       end

      def eds_search_modify(extra_params = {})
        params = eds_params_modify(extra_params)
        eds_index_path(params)
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

      # Create a link based on the current @search query, but
      # modified by whatever's passed in (facets, checkboxes, sort, paging),
      # and by possible advanced-search indicator
      def eds_params_modify(extra_params = {})
        params = {}

        params.merge!(extra_params)

        params['q'] = @q

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
