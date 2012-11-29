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
        @search_url = options.delete('search_url')
        @errors = nil
        Rails.logger.info "[Spectrum][GoogleApp] params: #{search_url}"
        begin 
          @raw_xml = Nokogiri::XML(HTTPClient.new.get_content(search_url))
          @documents = @raw_xml.css("R").collect { |xml_node| LibraryWeb::Document.new(xml_node) }
          @count = @raw_xml.at_css("M") ? @raw_xml.at_css("M").content.to_i : 0
        rescue Exception => e
          Rails.logger.error "[Spectrum][GoogleApp] error: #{e.message}"
          @errors = e.message
        end
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

      def previous_page?
        @start > 1
      end

      def start_item
        [@start + 1, total_items].min
      end

      def end_item
        [@start + @rows, total_items].min
      end
    
      def total_pages
        (total_items / @rows.to_f).ceil
      end


      def previous_page_path
        search_merge('start' => [@start - @rows, 1].max)
      end

      def next_page?
        end_item < total_items
      end

      def next_page_path
        search_merge('start' => @start + @rows)
      end

      def previous_page?
        start_item > 1 && total_items > 1
      end


      def page
        (@start / @rows) + 1
      end

      def successful?
        @errors.nil?
      end

      def total_items
        @count
      end


      def page_size
        @rows
      end


      def previous_page
        search_merge('start' => [@start - @rows, 0].max)
      end

      def next_page
        search_merge('start' => [@start + @rows, @count].min)
      end


      def page_count
        (@count / @rows) + 1
      end

      def set_page(page)
        new_page = [[1, page.to_i].max, page_count].min
        search_merge('start' => @rows * (new_page - 1))
      end
      def search_url

        "http://search.columbia.edu/search?site=CUL_LibraryWeb&sitesearch=&as_dt=i&client=cul_libraryweb&output=xml&ie=UTF-8&oe=UTF-8&filter=0&sort=date%3AD%3AL%3Adl&num=#{@rows}&x=0&y=0&q=#{CGI::escape(@q)}&start=#{@start}"
      end

      private


      def search_merge(params = {})
        library_web_index_path(@params.merge(params))
      end
    end
  end
end
