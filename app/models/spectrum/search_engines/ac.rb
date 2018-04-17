module Spectrum
  module SearchEngines
    class Ac

      # include ActionView::Helpers::NumberHelper
      include Rails.application.routes.url_helpers

      # Rails.application.routes.default_url_options = ActionMailer::Base.default_url_options
      attr_reader  :documents, :search, :count, :errors

      def initialize(options = {})
        search_url = build_search_url(options)

        # SCSB calls use Faraday, and can get both response codes and content.
        # @conn = Faraday.new(url: url)
        # raise "Faraday.new(#{url}) failed!" unless @conn
        # @conn.headers['Content-Type'] = 'application/json'
        # @conn.headers['api_key'] = @scsb_args[:api_key]
        # response = conn.post path, params.to_json
        # response_data = JSON.parse(response.body)

        client = HTTPClient.new
        response = client.get search_url
        status = response.status
        body = response.body

        # @results = HTTPClient.new.get_content(search_url)raise
        results = JSON.parse(response.body).with_indifferent_access

        @documents = Array(results[:records]).map { |item| AcDocument.new(item) }
        @count = results[:total_number_of_results]
        
        # begin
        #   # @raw_xml = Nokogiri::XML(HTTPClient.new.get_content(@search_url))
        #   # @documents = @raw_xml.css('R').map { |xml_node| LibraryWeb::Document.new(xml_node) }
        #   # @count = @raw_xml.at_css('M') ? @raw_xml.at_css('M').content.to_i : 0
        # rescue => ex
        #   Rails.logger.error "[Spectrum][GoogleCustomSearch] error: #{ex.message}"
        #   @errors = ex.message
        # end
      end

      def current_page
        @page
      end

      def page_size
        @per_page
      end

      # used by QuickSearch for "All Results" link
      def search_path
        ac_index_path(@params)
      end

      # def start_over_link
      #   library_web_index_path()
      # end

      def constraints_with_links
        [[@q, ac_index_path]]
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
        # [10, 25, 50, 100].map do |page_size|
        [10].map do |page_size|
          # do math so that current first item is still on screen.
          # (use zero-based params for talking to GA)
          new_page_number = @start.div page_size
          new_start_item = (new_page_number * page_size) + 1
          [search_merge('rows' => page_size, 'start' => new_start_item), page_size]
        end
      end

      private

      # https://academiccommons-dev.cdrs.columbia.edu/api/v1/search?
      #   search_type=keyword&q=test&page=1&per_page=25&sort=best_match&order=desc
      
      def build_search_url(options = {})
        url  = APP_CONFIG['ac']['api_url']
        search_path = APP_CONFIG['ac']['api_search_path']
        search_url = "#{url}#{search_path}"

        params = Hash.new
        [ 'search_type', 'q', 'page', 'per_page', 
          'sort', 'order'].each do |key|
            params[key] = options[key] if options[key].present?
        end
        
        search_url = "#{search_url}?#{params.to_query}" if params.present?
      end


      def search_merge(params = {})
        ac_index_path(@params.merge(params))
      end
    end
  end
end
