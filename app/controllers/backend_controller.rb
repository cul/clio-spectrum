# The front-end makes AJAX calls back to the Backend controller to get
# holdings information.  The Backend Controller in turn makes calls to
# a different web application, clio_backend, to get this data.
class BackendController < ApplicationController
  def url_for_id(id = nil)
    # raise
    if clio_backend_url = APP_CONFIG['clio_backend_url']
      return "#{clio_backend_url}/holdings/retrieve/#{id}"
    else
      fail 'clio_backend_url not found in APP_CONFIG'
    end
  end

  def holdings_httpclient
    hc = HTTPClient.new
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

    unless @id.match(/^\d+$/)
      logger.error "BackendController#holdings passed non-numeric id: #{@id}"
      render nothing: true and return
    end

    backend_url = url_for_id(@id)
    begin
      json_holdings = holdings_httpclient.get_content(backend_url)
      @holdings = JSON.parse(json_holdings)[@id]
    rescue HTTPClient::BadResponseError => ex
      logger.error "BackendController#holdings HTTPClient::BadResponseError URL: #{backend_url}  Exception: #{ex}"
      render nothing: true and return
    rescue HTTPClient::ReceiveTimeoutError => ex
      logger.error "HTTPClient::ReceiveTimeoutError URL: #{backend_url}"
      render nothing: true and return
    rescue => ex
      Rails.logger.error "BackendController error fetching holdings from #{backend_url}: #{ex.message}"
      render nothing: true and return
    end

    if @holdings.nil?
      logger.error "BackendController#holdings failed to fetch holdings for id: #{@id}"
      render nothing: true and return
    end

    # data retrieved successfully!  render and return an html snippet.
    render 'backend/holdings', layout: false
  end

  # ??? mail to who?
  # def holdings_mail
  #   @id = params[:id]
  #
  #   full_backend_url = "#{APP_CONFIG['clio_backend_url']}/holdings/retrieve/#{@id}"
  #   @holdings = JSON.parse(HTTPClient.get_content(full_backend_url))[@id]
  #
  #   render "backend/_holdings_mail", :layout => false
  # end

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
