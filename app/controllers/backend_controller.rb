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
      backend_holdings = JSON.parse(json_holdings)[@id]
    rescue HTTPClient::BadResponseError => ex
      logger.error "BackendController#holdings HTTPClient::BadResponseError URL: #{backend_url}  Exception: #{ex}"
      # render nothing: true and return
      head :bad_request and return
    rescue HTTPClient::ReceiveTimeoutError => ex
      logger.error "HTTPClient::ReceiveTimeoutError URL: #{backend_url}"
      # render nothing: true and return
      head :bad_request and return
    rescue => ex
      logger.error "BackendController error fetching holdings from #{backend_url}: #{ex.message}"
      # render nothing: true and return
      head :bad_request and return
    end

    if backend_holdings.nil?
      logger.error "BackendController#holdings failed to fetch holdings for id: #{@id}"
      render nothing: true and return
    end

    # # data retrieved successfully!  render an html snippet.
    # render 'backend/holdings', locals: {holdings: backend_holdings}, layout: false

    # HOLDINGS REVISION PROJECT
    # fetch holdings from solr document
    @response, @document = fetch params[:id]
    solr_holdings = get_document_holdings(@document)
    if solr_holdings.nil?
      logger.debug "BackendController#holdings: no solr holdings for id: #{@id}"
    end

    # Render BOTH holdings blocks, one on top of the other
    render 'backend/holdings', locals: {backend_holdings: backend_holdings, solr_holdings: solr_holdings}, layout: false

    if backend_holdings != solr_holdings
      logger.debug "Holdings Mismatch"
      logger.debug "backend holdings:\n#{backend_holdings.inspect}\n"
      logger.debug "solr holdings:\n#{solr_holdings.inspect}\n"
    end
  end

  private

  # HOLDINGS REVISION PROJECT

  def get_document_holdings(document)
    # Build holdings by working with full MARC record
    # We haven't pulled out Solr fields yet.
    marc = document.to_marc
    return get_marc_holdings(marc)
  end

  def get_marc_holdings(marc)
    # voyager_api is used within clio_backend like so:
    #   result = Voyager::Holdings::Collection.new_from_opac(bibid, @conn, api_server + holdings_service)
    #   result_hash = result.to_hash(:output_type => :condensed, :message_type => :short_message)

    result = Voyager::Holdings::Collection.new_from_marc(marc)
    result_hash = result.to_hash(:output_type => :condensed, :message_type => :short_message)

    return result_hash.with_indifferent_access
  end


end
