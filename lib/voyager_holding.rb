class Holding

  HOLDINGS_URL = "http://vetiver.cc.columbia.edu:7014/vxws/GetHoldingsService"
  COOKIE_STORE = Rails.root.to_s + "/tmp/cookies/holding_cookies.dat"

  attr_reader :bibid
  attr_accessor :results

  def initialize(bibid, *args)
    options = args.extract_options!

    @bibid = bibid
    @results = {}

    @http_client = options[:http_client]
  end

  def fetch_from_opac!
    raw_data = Hash.arbitrary_depth

    http_client do |hc|
      begin
        xml = Nokogiri::XML(hc.get_content(HOLDINGS_URL, :bibId => bibid.listify.join("&")))
      rescue
        @results= Hash.arbitrary_depth
        return self
      end


      get_content = lambda { |node| node ? node.content : nil }

      xml.root.add_namespace_definition("hol", "http://www.endinfosys.com/Voyager/holdings")
      xml.root.add_namespace_definition("mfhd", "http://www.endinfosys.com/Voyager/mfhd")
      xml.root.add_namespace_definition("item", "http://www.endinfosys.com/Voyager/item")

      xml.css("mfhd|mfhdRecord").collect do |holding|
        holding_id = holding.attributes["mfhdId"].value
        holding_hash = raw_data["holdings"][holding_id]

        holding_hash["call_number"] = holding.css("mfhd|mfhdData[name='callNumber']").collect(&:content).first
        holding_hash["location_name"] = holding.css("mfhd|mfhdData[name='locationDisplayName']").collect(&:content).first

        items = holding.css("mfhd|itemCollection").collect do |record|
          result = {}

          if record.at_css("item|itemData[name='statusCode']")
            result["code"] = get_content.call(record.at_css("item|itemData[name='statusCode']"))
            result["date"] = get_content.call(record.at_css("item|itemData[name='statusDate']"))
            result["tempLocation"] = get_content.call(record.at_css("item|itemLocationData[name='tempLocation']"))
          else
            result["code"] = "noitem"
          end

          result
        end

        holding_hash["items"] = items
      end

    end


    raw_data["status"] = true
    parse_raw_data!(raw_data)

    return self
  end

  def parse_raw_data!(raw_data)
    statuses = ["not_available", "checked_out", "non_circulating", "available"]
    raw_data["holdings"].each_pair do |holding_id, holding|
      holding["items"].each do |item|
        case  item["code"]
        when "1"
          item["desc"] = "Available"
          item["status"] = "available"
        when "2"
          item["desc"] = "Checked out, due #{Date.parse(item["date"]).to_formatted_s(:short)}"
          item["status"] = "checked_out"
        when "noitem"
          item["desc"] = "Does not circulate"
          item["status"] = "non_circulating"
        else
          item["desc"] = "Unavailable"
          item["status"] = "not_available"
        end
      end

      holding["status"] = statuses[holding["items"].collect { |i| statuses.index(i["status"]).to_i }.max.to_i]
    end

    @results = raw_data

  end


  def to_format(format = :object)
    case format
    when :json
      self.results.to_json

    when :hash
      self.results

    else
      self
    end
  end

  def self.fetch(*bibids)
    results = {}
    http_client_with_cookies do |hc|
      bibids.each do |id|
        results[id] = Holding.new(id, :http_client => hc).fetch_from_opac!.results
      end
    end
    results
  end

  private

  def http_client
    if @http_client
      yield @http_client
    else
      Holding.http_client_with_cookies do |hc|
        yield hc
      end
    end
  end

  def self.http_client_with_cookies
    hc = HTTPClient.new

    cookie_directory = File.dirname(COOKIE_STORE)
    FileUtils.mkdir_p(cookie_directory)

    hc.set_cookie_store(COOKIE_STORE)
    yield hc
    hc.cookie_manager.save_all_cookies(true)
  end
end

