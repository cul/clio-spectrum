class BackendController < ApplicationController
  def opac_holdings_data
    
    results = {}
    
    Voyager.opac_holdings_data(*params["bibid"].listify).each_pair do |bibid, holdings|
      holdings.each do |holding|
        results[holding.holding_id] = holding.image_for_display  
      end
    end


    render :json => results
  
  end

  def retrieve_book_jackets
    isbns = params["isbns"].listify
    results = {}
    hc = HTTPClient.new

    begin
      isbns.each do |isbn|
        unless results[isbn]
          query_url = 'http://books.google.com/books/feeds/volumes'
          logger.info("retrieving #{query_url}?q=isbn:#{isbn}")
          xml = Nokogiri::XML(hc.get_content(query_url, :q => "isbn:" + isbn))
          image_node = xml.at_css("feed>entry>link[@type^='image']")
          results[isbn] = image_node.attributes["href"].content.gsub(/zoom=./,"zoom=1") if image_node
        end
      end
    rescue Exception => e
      logger.warn("exception retrieving google book search: #{e.message}")
    end
    
    render :json => results
  end


end
