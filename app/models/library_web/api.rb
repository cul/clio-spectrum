class LibraryWeb::Api
  include ActionView::Helpers::NumberHelper
  include Rails.application.routes.url_helpers
  Rails.application.routes.default_url_options = ActionMailer::Base.default_url_options
  attr_reader :raw_xml, :docs, :page, :start, :count
  def initialize(params = {})
    @params = params
    @q = params['q'] || raise("No query string specified")
    @rows = (params['rows'] || 10).to_i
    @start = (params['start'] || 0).to_i
    @raw_xml = Nokogiri::XML(HTTPClient.new.get_content(search_url))
    @docs = @raw_xml.css("R").collect { |xml_node| LibraryWeb::Document.new(xml_node) }
    @count = @raw_xml.at_css("M") ? @raw_xml.at_css("M").content.to_i : 0
  end

  def page
    (@start / @rows) + 1
  end

  def entries_info
    if @count == 0
      " "
    else
      start_num = @start + 1
      end_num = @start + @rows

      txt = "Displaying "
      if end_num - start_num > 1
        txt += "items #{number_with_delimiter(start_num)} - #{number_with_delimiter(end_num)} of #{number_with_delimiter(@count)}"
      else
        txt += "item #{number_with_delimiter(start_num)} - #{number_with_delimiter(end_num)} of #{number_with_delimiter(@count)}"
      end

      txt
    end
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
