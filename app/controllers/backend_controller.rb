class BackendController < ApplicationController

  def url_for_id(id = nil)
    # raise
    if clio_backend_url = APP_CONFIG['clio_backend_url']
      return "#{clio_backend_url}/holdings/retrieve/#{id}"
    else
      raise "clio_backend_url not found in APP_CONFIG"
    end
  end

  def holdings_httpclient
    hc = HTTPClient.new()
    # The default is to wait 60/120 seconds - but we expect an instant response,
    # anything else means trouble, and we should give up immediately so as not
    # to not sit on resources.
    hc.connect_timeout = 10 # default 60
    hc.send_timeout    = 10 # default 120
    hc.receive_timeout = 10 # default 60
    hc
  end

  def holdings
    @id = params[:id]
    backend_url = url_for_id(@id)
    begin
      json_holdings = holdings_httpclient.get_content(backend_url)
      @holdings = JSON.parse( json_holdings )[@id]
    rescue HTTPClient::BadResponseError => e
      logger.error "#{self.class}##{__method__} HTTPClient::BadResponseError URL: #{backend_url}  Exception: #{e}"
      render nothing: true and return
    rescue HTTPClient::ReceiveTimeoutError => e
      logger.error "HTTPClient::ReceiveTimeoutError URL: #{backend_url}"
      render nothing: true and return
    rescue => e
      Rails.logger.error "BackendController error fetching holdings from #{backend_url}: #{e.message}"      
    end

    if @holdings.nil?
      logger.error "#{self.class}##{__method__} failed to fetch holdings for id: #{@id}"
      render nothing: true and return
    end

    # data retrieved successfully!  render and return an html snippet.
    render "backend/holdings", :layout => false
  end

  def holdings_mail

    @holdings = JSON.parse(HTTPClient.get_content("#{APP_CONFIG['clio_backend_url']}/holdings/retrieve/#{params[:id]}"))[params[:id]]
    @id = params[:id]

    render "backend/_holdings_mail", :layout => false
  end

  #
  # marquis, 5/2013 - obsolete?
  #
  # def retrieve_book_jackets
  #   isbns = params["isbns"].listify
  #   results = {}
  #   hc = HTTPClient.new
  #
  #   begin
  #     isbns.each do |isbn|
  #       unless results[isbn]
  #         query_url = 'http://books.google.com/books/feeds/volumes'
  #         logger.info("retrieving #{query_url}?q=isbn:#{isbn}")
  #         xml = Nokogiri::XML(hc.get_content(query_url, :q => "isbn:" + isbn))
  #         image_node = xml.at_css("feed>entry>link[@type^='image']")
  #         results[isbn] = image_node.attributes["href"].content.gsub(/zoom=./,"zoom=1") if image_node
  #       end
  #     end
  #   rescue => e
  #     logger.warn("#{self.class}##{__method__} exception retrieving google book search: #{e.message}")
  #   end
  #
  #   render :json => results
  # end


end
