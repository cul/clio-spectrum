class LibraryWeb::API
  attr_reader :raw_xml, :docs, :page, :start, :count
  def initialize(params = {})
    
    @q = params[:q] || raise("No query string specified")
    @rows = (params[:rows] || 10).to_i
    @page = (params[:page] || 1).to_i
    @raw_xml = Nokogiri::XML(HTTPClient.new.get_content(search_url))
    @docs = @raw_xml.css("R").collect { |xml_node| LibraryWeb::Document.new(xml_node) }
    @count = @raw_xml.at_css("M") ? @raw_xml.at_css("M").content.to_i : 0
    @start = ([@page, 1].min - 1) * @rows
  end


  def search_url

    "http://search.columbia.edu/search?site=CUL_LibraryWeb&sitesearch=&as_dt=i&client=cul_libraryweb&output=xml&ie=UTF-8&oe=UTF-8&filter=0&sort=date%3AD%3AL%3Adl&num=#{@rows}&x=0&y=0&q=#{CGI::escape(@q)}&start=#{@start}"
  end
end
