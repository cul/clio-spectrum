module Voyager
  HOLDINGS_URL = "http://bearberry.cc.columbia.edu:7014/vxws/GetHoldingsService"
  COOKIE_STORE = RAILS_ROOT + "/tmp/cookies/holding_cookies.dat"


  def self.opac_holdings_data(*bibids)
    results = {}

    http_client_with_cookies do |hc|
      bibids.each do |bibid|

        xml = Nokogiri::XML(hc.get_content(HOLDINGS_URL, :bibId => bibid))
        
        xml.root.add_namespace_definition("hol", "http://www.endinfosys.com/Voyager/holdings")
        xml.root.add_namespace_definition("mfhd", "http://www.endinfosys.com/Voyager/mfhd")
        xml.root.add_namespace_definition("item", "http://www.endinfosys.com/Voyager/item")
        holdings = xml.css("mfhd|mfhdRecord").collect do |holding|
          holding_id = holding.attributes["mfhdId"].value
          call_number = holding.css("mfhd|mfhdData[name='callNumber']").collect(&:content).first
          location_name = holding.css("mfhd|mfhdData[name='locationDisplayName']").collect(&:content).first
          
          statuses= holding.css("item|itemRecord").collect do |record|
            code = record.at_css("item|itemData[name='statusCode']").content
            desc = case code
            when "1"
              "Available"
            when "2"
              "Checked out, due #{Date.parse(record.at_css("item|itemData[name='statusDate']").content).to_formatted_s(:short)}"
            else
              "Unavailable"
            end

            [code, desc]
          end


       

        
          Holding.new(holding_id, call_number, location_name, statuses)
        end

        results[bibid] = holdings    
      end
    end
    
    return results
  end

  private

  def self.http_client_with_cookies
    hc = HTTPClient.new
    hc.set_cookie_store(COOKIE_STORE)
    yield hc
    hc.cookie_manager.save_all_cookies(true)
  end

  class Holding
    attr_reader :holding_id, :call_number, :location_name, :statuses
    
    def initialize(holding_id, call_number, location_name, statuses)
      @holding_id = holding_id
      @call_number = call_number
      @location_name = location_name
      @statuses = statuses
    end

    def is_available?
      @statuses.collect(&:first).include?("1") && !@location_name.include?("Temporarily unavailable.")
    end

    def status_for_display
      if @location_name == "Online" || is_available?
        ""
      else
        (@statuses.first || [""]).last
      end
    end
      
    def image_for_display
      if @location_name == "Online"
        "icons/noncirc.png"
      elsif is_available?
        "icons/available.png"
      else
        "icons/unavailable.png"
      end

    end
  end

end
