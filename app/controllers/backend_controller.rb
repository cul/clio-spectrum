class BackendController < ApplicationController
  def opac_holdings_data
    holdings_url = "http://bearberry.cc.columbia.edu:7014/vxws/GetHoldingsService"
    results = Hash.arbitrary_depth
    
    bibids = params["bibid"].listify

    hc = HTTPClient.new
    

    bibids.each do |bibid|
      begin
        any_available = false

        xml = Nokogiri::XML(hc.get_content(holdings_url, :bibId => bibid))
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


    render :json => results
  
  end



end
