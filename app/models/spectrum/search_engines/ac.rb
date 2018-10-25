module Spectrum
  module SearchEngines
    class Ac

      # include ActionView::Helpers::NumberHelper
      include Rails.application.routes.url_helpers

      # Rails.application.routes.default_url_options = ActionMailer::Base.default_url_options
      attr_reader  :documents, :search, :count, :errors, :filters, :facets, :facet_config

      def initialize(options = {})
        search_url = build_search_url(options)

        @params = options
        # truncate to length that the AC API can handle
        @q = (options['q'] || '')[0,1000]
        @search_field = options['search_field']
        @rows = (options['per_page'] || 10).to_i
        @page = (options['page'] || 1).to_i
        @start = ((@page - 1) * @rows) + 1
        @errors = nil

        begin
          client = HTTPClient.new
          client.connect_timeout = 10 # default 60
          client.send_timeout    = 10 # default 120
          client.receive_timeout = 10 # default 60
          response = client.get search_url

          # Did the server respond with a non-OK status?
          if response.status != 200
            @errors = ActionController::Base.helpers.strip_tags(response.body)
            Rails.logger.error "Spectrum::SearchEngines::Ac get(#{search_url}) returned #{response.status}: #{@errors}"
            return
          end

          results = JSON.parse(response.body).with_indifferent_access
        rescue => ex
          Rails.logger.error "Spectrum::SearchEngines::Ac error: #{ex.message}"
          @errors = ex.message
          return
        end

        @documents = Array(results[:records]).map { |item| AcDocument.new(item) }
        @count = results[:total_number_of_results]
 
        # These are the applied facets
        @filters = results['params']['filters']
        # These are the facet values/counts from the full set of result docs
        @facets = results['facets']
        # complex facet structure, including active flags, enable/disable links, etc.
        @facet_config = build_facet_config(@facets, @filters)
      
      end

      def current_page
        @page
      end

      def page_size
        @rows
      end

      # used by QuickSearch for "All Results" link
      def search_path
        ac_index_path(@params)
      end

      # def start_over_link
      #   library_web_index_path()
      # end_item

      def constraints_with_links
        constraints = []

        # Add the basic query term, possibly fielded.
        query = @q.dup
        query = "#{@search_field.titleize}: #{query}" if @search_field.in?(['title', 'subject'])
        constraints << [query, ac_index_path]
        
        # Add any facet filter contraints.
        # Zero or more filter fields, each with possibly multiple values, e.g.:
        #     "filters": {
        #       "subject": [
        #         "Medicine",
        #         "Epidemiology"
        #       ],
        #       "department"; [
        #         "Computer Science"
        #       ]
        #     }

        @filters.each do |filter_name, filter_value_list|
          filter_value_list.each do |value|
            remove_facet_url = build_remove_facet_url(filter_name, value)
            constraints << ["#{filter_name.titleize}: #{value}", remove_facet_url]
            # new_params = @params.dup.except(filter_name)
            # new_params.merge( filter_value_list.except(value) ) unless filter_value_list.size == 1
            # constraints << ["#{filter_name.titleize}: #{value}", ac_index_path(new_params)]
          end
        end
        
        
        return constraints
      end

      def start_item
        [@start, @count].min
      end

      def end_item
        [@start + @rows - 1, @count].min
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
        search_merge(page: @page - 1)
      end

      def next_page_path
        search_merge(page: @page + 1)
      end

      # List of paging options, turned into a drop-down in sorting/paging partial
      def page_size_with_links
        [10, 25, 50, 100].map do |per_page|
          # do math so that current first item is still on screen.
          # (use zero-based params for talking to GA)
          new_page_number = (@start.div per_page) + 1
          [search_merge('page' => new_page_number, 'per_page' => per_page), per_page]
        end
      end

      # List of sort options, turned into a drop-down in index_toolbar partial
      def sorts_with_links
        [
          [search_merge(sort: 'best_match', order: 'desc', page: '1'), 'Relevancy'],

          [search_merge(sort: 'date', order: 'asc', page: '1'), 'Published Earliest'],
          [search_merge(sort: 'date', order: 'desc', page: '1'), 'Published Latest'],

          [search_merge(sort: 'title', order: 'asc', page: '1'), 'Title A-Z'],
          [search_merge(sort: 'title', order: 'desc', page: '1'), 'Title Z-A'],
        ]
      end

      def current_sort_name
        sort = @params['sort'] || 'best_match'
        order = @params['order'] || 'desc'
        
        case sort

        # default case - relevancy sort, descending
        when 'best_match'
          return 'Relevancy'

        # date sort - we label this "Published"
        when 'date'
          case order
          when 'asc'
            return 'Published Earliest'
          else
            return 'Published Latest'
          end

        # Title Sort - 
        when 'title'
          case order
          when 'asc'
            return 'Title A-Z'
          else
            return 'Title Z-A'
          end

        # Unrecognized?  Just echo to screen.
        else
          return "#{sort} #{order}".titleize
        end

      end 
      
      
      private

      # https://academiccommons-dev.cdrs.columbia.edu/api/v1/search?
      #   search_type=keyword&q=test&page=1&per_page=25&sort=best_match&order=desc
      
      # Build a search URL for querying the AC API
      # Translate options (CGI params) to API params
      def build_search_url(options = {})
        url  = APP_CONFIG['ac']['api_url']
        search_path = APP_CONFIG['ac']['api_search_path']
        search_url = "#{url}#{search_path}"

        api_params = Hash.new
      
        # basic query params
        basics = [ 'q', 'page', 'per_page', 'sort', 'order']
        basics.each do |key|
          api_params[key] = options[key] if options[key].present?
        end

        # If we get non-AC sort params, either fix or ignore
        sort_key = options['sort']
        order_key = options['order']

        # combined, e.g.:  sort=pub_date_sort+desc
        if sort_key.present? && sort_key.match(/\w+ \w+sc/)
          sort_key, order_key = sort_key.match(/(\w+) (\w+sc)/).captures
        end
        sort_key = 'date' if sort_key == 'pub_date_sort'
        if ['best_match', 'date', 'title'].include? sort_key
          api_params['sort'] = sort_key
          if ['asc', 'desc'].include? order_key
            api_params['order'] = order_key
          end
        end
        
        # *** remap params ***
        # "SEARCH FIELD" V.S. "SEARCH TYPE"
        key_remaps = {
          'search_field' => 'search_type'
        }
        value_remaps = {
          'all_fields' => 'keyword',
          'all' => 'keyword',
        }
        key_remaps.each do |clio_key, api_key|
          # We have a key that needs to be remapped
          if options[clio_key].present?
            # if the value is in our remap table, remap value also
            clio_value = options[clio_key]
            api_value = value_remaps[clio_value] || clio_value
            api_params[api_key] = api_value
          end

        end
        
        
        # facet filter params
        filters = ['author', 'date', 'department', 'subject', 'type', 'columbia_series']
        filters.each do |key|
          api_params[key] = options[key] if options[key].present?
        end 

        # DISSERTATIONS
        # hardcode filter to show only dissertations if we're in that datasource
        api_params['type'] = 'Theses' if options['datasource'] == 'ac_dissertations'

        search_url = "#{search_url}?#{api_params.to_query}" if api_params.present?
        Rails.logger.debug "Spectrum::SearchEngines::Ac build_search_url(options)\n    #{search_url}"
        return search_url
      end


      def search_merge(params = {})
        ac_index_path(@params.merge(params))
      end

      # complex facet structure, including active flags, enable/disable links, etc.
      AC_FACET_LIMIT = 10
      def build_facet_config(facets, filters)
        
        config = Hash.new
        
        config = facets.map { |facet_name, facet_value_list|
          facet_active = @filters.key?(facet_name)
          
          new_value_list = []
          facet_value_list.map { |value, count|
            break if new_value_list.size > AC_FACET_LIMIT
            
            # each facet-value needs the following attribute fields:
            new_value_list << { 
              name:       value,
              count:      count,
              active:     facet_active && value.in?(@filters[facet_name]),
              add_url:    build_add_facet_url(facet_name, value),
              remove_url: build_remove_facet_url(facet_name, value)
            }
          }
         
          #  Return this hash structure for each facet filter
          { name:    facet_name,
            active:  facet_active,
            values:  new_value_list
          }
          
        }

        return config
      end

      def build_add_facet_url(facet_name, value)
        applied_values = Array( @filters[facet_name] )
        # Don't add if it's already applied
        return if value.in?(applied_values)
        
        new_params = @params.dup.except(facet_name)
        new_params.merge!( facet_name => applied_values + Array(value) )

        restart_ac_index_path(new_params)
      end
    
      def build_remove_facet_url(facet_name, value)
        return unless facet_name.in?(@filters)

        applied_values = Array( @filters.dup[facet_name] )
        # Don't remove if it's not applied
        return unless value.in?(applied_values)

        new_params = @params.dup.except(facet_name)
        new_params.merge!( facet_name => applied_values - Array(value) ) if applied_values.size > 1

        restart_ac_index_path(new_params)
      end


      def restart_ac_index_path(params)
        # reset page number for new searches
        params.delete('page')
        ac_index_path(params)
      end
    
    end
  end
end
