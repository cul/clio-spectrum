class BackendController < ApplicationController
  def opac_holdings_data
    start = Time.now

    results = Hash.arbitrary_depth
    
    bibids = params["bibid"].listify


    hc = HTTPClient.new
    hc.set_cookie_store(RAILS_ROOT+"/tmp/cookies/holding_cookies.dat")

    logger.debug(Time.now-start)
    bibids.each do |bibid|
      begin
        any_available = false

        logger.info("retrieving #{holdings_url}?bibId=#{bibid}")
        xml = Nokogiri::XML(hc.get_content(holdings_url, :bibId => bibid))
        logger.debug(Time.now-start)
        xml.root.add_namespace_definition("hol", "http://www.endinfosys.com/Voyager/holdings")
        xml.root.add_namespace_definition("mfhd", "http://www.endinfosys.com/Voyager/mfhd")
        xml.root.add_namespace_definition("item", "http://www.endinfosys.com/Voyager/item")
        xml.css("mfhd|mfhdRecord").each do |holding|
          holding_id = holding.attributes["mfhdId"].value
          available = holding.css("item|itemData[name='statusCode']").collect(&:content).include?("1")
          results["holdingsId"][holding_id] = available ? "available" : "unavailable"
          any_available = true if available
        end

        results["bibId"][bibid] = any_available ? "available" : "unavailable"
      rescue Exception => e
        results["bibId"][bibid] = "error" 
      end
    end

    hc.cookie_manager.save_all_cookies(true)
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
