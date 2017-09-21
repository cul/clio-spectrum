# The front-end makes AJAX calls back to the Backend controller to get
# holdings information.  The Backend Controller in turn makes calls to
# a different web application, clio_backend, to get this data.
class BackendController < ApplicationController

  def url_for_id(id)
    BackendController.url_for_id(id)
  end

  def self.url_for_id(id = nil, action = 'retrieve')
    if clio_backend_url = APP_CONFIG['clio_backend_url']
      return "#{clio_backend_url}/holdings/#{action}/#{id}"
    else
      fail 'clio_backend_url not found in APP_CONFIG'
    end
  end

  def backend_httpclient
    BackendController.backend_httpclient
  end

  def self.backend_httpclient
    hc = HTTPClient.new
    # The default is to wait 60/120 seconds - but we expect an instant response,
    # anything else means trouble, and we should give up immediately so as not
    # to not sit on resources.
    hc.connect_timeout = 10 # default 60
    hc.send_timeout    = 10 # default 120
    hc.receive_timeout = 10 # default 60
    hc
  end

  # Need to support this kind of call:
  # @circ_status = BackendController.circ_status(params[:id])

  def self.circ_status(id)
    unless id.match(/^\d+$/)
      logger.error "BackendController#circ_status passed non-numeric id: #{id}"
      return nil
    end

    backend_url = url_for_id(id, 'circ_status')
    begin
      json_results = backend_httpclient.get_content(backend_url)
      backend_results = JSON.parse(json_results).with_indifferent_access
    rescue => ex
      logger.error "BackendController#circ_status #{ex} URL: #{backend_url}"
      return nil
    end

    if backend_results.nil? or backend_results.empty?
      logger.error "BackendController#circ_status URL: #{backend_url} nothing returned"
      return nil
    end

    # data retrieved successfully...
    return backend_results
  end


  # The SCSB availability API returns an array looks like this:
  # [
  #   {
  #     "itemBarcode": "CU18799175",
  #     "itemAvailabilityStatus": "Available",
  #     "errorMessage": null
  #   }
  # ]
  # but our code simplifies this into a simple hash, like this:
  # {
  #   "CU18799175"  =>  "Available"
  # }
  def self.scsb_status(id)
    if id.empty?
      logger.error "BackendController#scsb_status passed empty id"
      return nil
    end
    
    bibliographicId = id.to_s

    # Default - assume Columbia material
    institutionId = 'CUL'

    # But if it's a SCSB Id...
    if bibliographicId.match /^SCSB\-/
      institutionId, dash, bibliographicId = bibliographicId.partition('-')
    end

    scsb_status = Recap::ScsbRest.get_bib_availability(bibliographicId, institutionId) || {}
  end


  def holdings
    @id = params[:id]
 
    logger.error "Legacy BackendController#holdings called for id: #{@id}"

    unless @id.match(/^\d+$/)
      logger.error "BackendController#holdings passed non-numeric id: #{@id}"
      render nothing: true and return
    end

    backend_url = url_for_id(@id)
    begin
      json_holdings = backend_httpclient.get_content(backend_url)
      backend_holdings = JSON.parse(json_holdings)[@id]
    rescue HTTPClient::BadResponseError => ex
      logger.error "BackendController#holdings HTTPClient::BadResponseError URL: #{backend_url}  Exception: #{ex}"
      head :bad_request and return
    rescue HTTPClient::ReceiveTimeoutError => ex
      logger.error "HTTPClient::ReceiveTimeoutError URL: #{backend_url}"
      head :bad_request and return
    rescue => ex
      logger.error "BackendController error fetching holdings from #{backend_url}: #{ex.message}"
      head :bad_request and return
    end

    if backend_holdings.nil?
      logger.error "BackendController#holdings failed to fetch holdings for id: #{@id}"
      render nothing: true and return
    end

    # data retrieved successfully!  render an html snippet.
    render 'backend/holdings', locals: {holdings: backend_holdings}, layout: false

    # # HOLDINGS REVISION PROJECT
    # # fetch holdings from solr document
    # @response, @document = fetch params[:id]
    # solr_holdings = get_document_holdings(@document)
    # if solr_holdings.nil?
    #   logger.debug "BackendController#holdings: no solr holdings for id: #{@id}"
    # end
    # 
    # # Render BOTH holdings blocks, one on top of the other
    # render 'backend/holdings', locals: {backend_holdings: backend_holdings, solr_holdings: solr_holdings}, layout: false

    # if backend_holdings != solr_holdings
    #   logger.debug "Holdings Mismatch"
    #   logger.debug "backend holdings:\n#{backend_holdings.inspect}\n"
    #   logger.debug "solr holdings:\n#{solr_holdings.inspect}\n"
    # end
  end

  private

# This is done directly in catalog controller, 
# not in a separate call to backend controller
  # # HOLDINGS REVISION PROJECT
  # 
  # def get_document_holdings(document)
  #   # Build holdings by working with full MARC record
  #   # We haven't pulled out Solr fields yet.
  #   marc = document.to_marc
  #   return get_marc_holdings(marc)
  # end
  # 
  # def get_marc_holdings(marc)
  #   # voyager_api is used within clio_backend like so:
  #   #   result = Voyager::Holdings::Collection.new_from_opac(bibid, @conn, api_server + holdings_service)
  #   #   result_hash = result.to_hash(:output_type => :condensed, :message_type => :short_message)
  # 
  #   result = Voyager::Holdings::Collection.new_from_marc(marc)
  #   # result_hash = result.to_hash(:output_type => :condensed, :message_type => :short_message)
  #   result_hash = result.to_hash(:output_type => :condensed, :message_type => :long_message)
  # 
  #   return result_hash.with_indifferent_access
  # end


end
