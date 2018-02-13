class Lweb::Document
  attr_accessor :url, :title, :summary, :mime

  def initialize(item = nil)
    if item

      # content_or_nil = lambda { |node| node ? node.content : nil }
      # @url     = content_or_nil.call(xml_node.at_css('UE'))
      # @title   = content_or_nil.call(xml_node.at_css('T'))
      # @summary = content_or_nil.call(xml_node.at_css('S'))
      # @mime    = content_or_nil.call(xml_node.attribute('MIME'))
      
      @url     = item.link
      @title   = item.title
      @summary = item.html_snippet
      @mime    = item.mime

    end
  end
end
