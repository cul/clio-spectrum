class LibraryWeb::Document 
  attr_accessor :url, :title, :summary
  def initialize(xml_node = nil)
    if xml_node
      
      content_or_nil = lambda { |node| node ? node.content : nil }
       
      @url = content_or_nil.call(xml_node.at_css('UE')),
      @title = content_or_nil.call(xml_node.at_css('T')),
      @summary = content_or_nil.call(xml_node.at_css('S'))
      
    end
  end
end
