module Spectrum
  module SearchEngines
    class GoogleAppliance
      include ActionView::Helpers::NumberHelper
      include Rails.application.routes.url_helpers
      Rails.application.routes.default_url_options = ActionMailer::Base.default_url_options
      attr_reader  :documents, :search, :count, :errors

      def initialize(options = {})
        @params = options
        @q = options['q'] || raise("No query string specified")
        @rows = (options['rows'] || 10).to_i
        @start = (options['start'] || 0).to_i
        @sitesearch = options['sitesearch'] || ''
        @search_url = options.delete('search_url')
        @errors = nil
        Rails.logger.debug "[Spectrum][GoogleApp] params: #{search_url}"
        begin
          @raw_xml = Nokogiri::XML(HTTPClient.new.get_content(search_url))
          @documents = @raw_xml.css("R").collect { |xml_node| LibraryWeb::Document.new(xml_node) }
          @count = @raw_xml.at_css("M") ? @raw_xml.at_css("M").content.to_i : 0
        rescue => ex
          Rails.logger.error "[Spectrum][GoogleApp] error: #{ex.message}"
          @errors = ex.message
        end
      end

      def current_page
        (@start.div @rows) + 1
      end

      def page_size
        @rows || 10
      end

      def search_path
        @search_url || library_web_index_path(@params)
      end

      def start_over_link
        library_web_index_path()
      end

      def constraints_with_links
        [[@q, library_web_index_path()]]
      end

      def start_item
        [@start + 1, total_items].min
      end

      def end_item
        [@start + @rows, total_items].min
      end

      def next_page?
        end_item < total_items
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
        search_merge('start' => [@start - @rows, 0].max)
      end

      def next_page_path
        search_merge('start' => @start + @rows)
      end

      # List of paging options, turned into a drop-down in summon's sorting/paging partial
      def page_size_with_links
        [10,25,50,100].collect do |page_size|
          # do math so that current first item is still on screen.
          # (use zero-based params for talking to GA)
          new_page_number = @start.div page_size
          new_start_item = new_page_number * page_size
          [ search_merge('rows' => page_size, 'start' => new_start_item), page_size]
        end
      end


      def search_url
        default_params = {
          'site'    => 'CUL_LibraryWeb',
          'as_dt'   => 'i',
          'client'  => 'cul_libraryweb',
          'output'  => 'xml',
          'ie'      => 'UTF-8',
          'oe'      => 'UTF-8',
          'filter'  => '0',
          'sort'    => 'date:D:L:dl',
          'x'       => '0',
          'y'       => '0',
        }

        url = "http://search.columbia.edu/search?#{default_params.to_query}"
        url += "&sitesearch=#{@sitesearch}"
        url += "&num=#{@rows}"
        url += "&start=#{@start}"
        url += "&q=#{CGI::escape(@q)}"
        url
      end

      private

      def search_merge(params = {})
        library_web_index_path(@params.merge(params))
      end

    end
  end
end
