module Spectrum
  module Engines
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
        # Rails.logger.debug "[Spectrum][GoogleApp] params: #{search_url}"
        begin
          @raw_xml = Nokogiri::XML(HTTPClient.new.get_content(search_url))
          @documents = @raw_xml.css("R").collect { |xml_node| LibraryWeb::Document.new(xml_node) }
          @count = @raw_xml.at_css("M") ? @raw_xml.at_css("M").content.to_i : 0
        # rescue => e
        #   Rails.logger.error "#{self.class}##{__method__} [Spectrum][GoogleApp] error: #{e.message}"
        #   @errors = e.message
        end
      end

      # unused?
      # def results
      #   documents
      # end

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

      # unused?
      # def total_pages
      #   (total_items / @rows.to_f).ceil
      # end

      # unused?
      # def page_count
      #   (@count / @rows) + 1
      # end


      def next_page?
        end_item < total_items
      end

      def previous_page?
        start_item > 1 && total_items > 1
      end

      # unused?
      # def previous_page?
      #   @start > 1
      # end

      # unused?
      # def page
      #   (@start / @rows) + 1
      # end

      def successful?
        @errors.nil?
      end

      def total_items
        @count
      end

      # unused?
      # def page_size
      #   @rows
      # end


      def previous_page_path
        search_merge('start' => [@start - @rows, 0].max)
      end

      # unused?
      # def previous_page
      #   search_merge('start' => [@start - @rows, 0].max)
      # end

      def next_page_path
        search_merge('start' => @start + @rows)
      end

      # unused?
      # def next_page
      #   search_merge('start' => [@start + @rows, @count].min)
      # end

      # unused?
      # def set_page(page)
      #   new_page = [[1, page.to_i].max, page_count].min
      #   search_merge('start' => @rows * (new_page - 1))
      # end

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
