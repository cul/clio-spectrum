module Spectrum
  module SearchEngines
    class GoogleCustomSearch
      require 'google/apis/customsearch_v1'
      Customsearch = Google::Apis::CustomsearchV1

      include Rails.application.routes.url_helpers

      attr_reader :documents, :search, :count, :errors

      def initialize(options = {})
        raise('No query string specified') unless options['q']

        # Initialize object instance variables
        @documents = []
        @count = 0
        @errors = nil
        
        # We don't support web searches of over X characters
        options['q'] = options['q'].truncate(200)

        @params = options
        @q = options['q']

        # Skip search for certain queries
        return if @q.match(/^\d+$/);  # Skip all-numeric queries

        # NEXT-1587 - support sitesearch for LWeb
        site_search = options['site_search'] || ''
        site_search_filter = options['site_search_filter'] || 'i'

        @rows = (options['rows'] || 10).to_i
        @start = (options['start'] || 1).to_i
        cs_id  = APP_CONFIG['google']['custom_search_id']
        cs_key = APP_CONFIG['google']['custom_search_key']

        service_params = {
          cx:    cs_id,
          start: @start,
          num:   @rows
        }

        if site_search.present?
          service_params[:site_search] = site_search
          service_params[:site_search_filter] = site_search_filter
        end

        Rails.logger.debug "[Spectrum][GoogleCustomSearch] service_params: #{service_params}"

        # service = Customsearch::CustomsearchService.new
        service = Customsearch::CustomSearchAPIService.new
        service.key = cs_key
          
        # Cache to avoid redundant searches - needs to include all dynamic params
        cache_key = "gcs:#{@q};#{@rows};#{@start};#{site_search};#{site_search_filter}"
        results = Rails.cache.fetch(cache_key, expires_in: 7.day) do
          Rails.logger.debug "GoogleCustomSearch cache miss for cache_key #{cache_key}"
          # service.list_cse_siterestricts(@q, cx: cs_id, start: @start, num: @rows)
          # service.list_cse_siterestricts(@q, service_params)
          service_params[:q] = @q
          service.list_cse_siterestricts(service_params)
        end

        @documents = Array(results.items).map { |item| LwebDocument.new(item) }
        @count = results.search_information.total_results.to_i
      end

      def current_page
        (@start.div @rows) + 1
      end

      def page_size
        @rows || 100
      end

      # used by QuickSearch for "All Results" link
      def search_path
        lweb_index_path(@params)
      end

      def constraints_with_links
        [[@q, lweb_index_path]]
      end

      def start_item
        [@start, total_items].min
      end

      def end_item
        [@start + @rows - 1, total_items].min
      end

      def next_page?
        # server-side limit of 10 pages
        (end_item < total_items) && current_page < 10
      end

      def previous_page?
        start_item > 1 && total_items > 1
      end

      def successful?
        @errors.nil?
      end

      def total_items
        @count
      end

      def previous_page_path
        search_merge('start' => [@start - @rows, 1].max)
      end

      def next_page_path
        search_merge('start' => @start + @rows)
      end

      # List of paging options, turned into a drop-down in sorting/paging partial
      def page_size_with_links
        # server-side limit of 10 results per page
        [10].map do |page_size|
          # do math so that current first item is still on screen.
          # (use zero-based params for talking to GA)
          new_page_number = @start.div page_size
          new_start_item = (new_page_number * page_size) + 1
          [search_merge('rows' => page_size, 'start' => new_start_item), page_size]
        end
      end

      private

      def search_merge(params = {})
        lweb_index_path(@params.merge(params))
      end
    end
  end
end
