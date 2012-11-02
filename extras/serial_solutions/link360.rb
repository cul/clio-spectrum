module SerialSolutions
  class Link360
    attr_reader :request_url
    attr_reader :title, :creator, :source, :date, :issns, :volume, :issue, :spage
    attr_reader :holdings

    def initialize(open_url, config = APP_CONFIG['link360'])
      @request_url =  APP_CONFIG['link360']['open_url_prefix'].to_s + open_url.to_s
      Rails.logger.info "[360LINK] Request: #{@request_url}"
      raw_xml = Nokogiri::XML(HTTPClient.new.get_content(@request_url))
      @response = {}
      parse_xml(raw_xml)

    end

    private

    def parse_xml(xml)
      content_or_nil = lambda { |node, css| res = node.at_css(css); res ? res.content : nil }

      @title = content_or_nil.call(xml, 'dc|title')
      @creator = content_or_nil.call(xml, 'dc|creator')
      @source = content_or_nil.call(xml, 'dc|source')
      @date = content_or_nil.call(xml, 'dc|date')

      @issns = xml.css('ssopenurl|issn').collect do |issn|
        {:type => issn.attributes['type'].content, :value => issn.content}
      end

      @volume = content_or_nil.call(xml, 'ssopenurl|volume')
      @issue = content_or_nil.call(xml, 'ssopenurl|issue')
      @spage = content_or_nil.call(xml, 'ssopenurl|spage')

      @holdings = xml.css('ssopenurl|linkGroup').collect do |link_group|
        holding = link_group.at_css('ssopenurl|holdingData')

        result = { 
          :start_date => content_or_nil.call(holding, 'ssopenurl|startDate'),
          :end_date => content_or_nil.call(holding, 'ssopenurl|endDate') || "present",
          :provider_id => content_or_nil.call(holding, 'ssopenurl|providerId'),
          :provider_name => content_or_nil.call(holding, 'ssopenurl|providerName'),
          :database_id => content_or_nil.call(holding, 'ssopenurl|databaseId'),
          :database_name => content_or_nil.call(holding, 'ssopenurl|databaseName')

        }

        result[:urls] = {}
        link_group.css('ssopenurl|url').each do |url|
          result[:urls][url.attributes['type'].content] = url.content
        end

        result
      end

    end
  end
end
