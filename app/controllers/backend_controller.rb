# The front-end makes AJAX calls back to the Backend controller to get
# holdings information.  The Backend Controller in turn makes calls to
# a different web application, clio_backend, to get this data.
class BackendController < ApplicationController
  def url_for_id(id)
    BackendController.url_for_id(id)
  end

  def self.url_for_id(id = nil, action = 'holdings/retrieve')
    if clio_backend_url = APP_CONFIG['clio_backend_url']
      return "#{clio_backend_url}/#{action}/#{id}"
    else
      raise 'clio_backend_url not found in APP_CONFIG'
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
    hc.connect_timeout = 5 # default 60
    hc.send_timeout    = 5 # default 120
    hc.receive_timeout = 5 # default 60
    hc
  end

  # Need to support this kind of call:
  # @circ_status = BackendController.circ_status(params[:id])
  #
  # The circ_status hash ("backend_results") looks like this (bib/holding(s)/item(s)):
  # {
  #   123: {
  #     144: {
  #       540: {
  #         holdLocation: "",
  #         itemLabel: "",
  #         requestCount: 0,
  #         statusCode: 1,
  #         statusDate: "",
  #         statusPatronMessage: ""
  #       }
  #     }
  #   }
  # }
  def self.circ_status(id)
    # NEXT-1664 - Restoring physical book access, via the Paging service
    # # # LIBSYS-2891 / LIBSYS-2892 - ALL libraries closed - all circulating material unavailable
    # # return nil
    
    # We should only have Voyager IDs, or timestamp records (99i, 99c, etc.)
    unless id.match(/^\d+$/) || id.match(/^99\w$/)
      logger.warn "BackendController#circ_status passed non-numeric id: #{id}"
      return nil
    end

    backend_url = url_for_id(id, 'holdings/circ_status')
    begin
      json_results = backend_httpclient.get_content(backend_url)
      backend_results = JSON.parse(json_results).with_indifferent_access
    rescue => ex
      logger.error "BackendController#circ_status #{ex} URL: #{backend_url}"
      return nil
    end

    if backend_results.nil? || backend_results.empty?
      logger.warn "BackendController#circ_status URL: #{backend_url} nothing returned"
      return nil
    end

    # data retrieved successfully...
    backend_results
  end

  # The SCSB status API returns an array looks like this:
  # [
  #   {
  #     "itemBarcode": "CU18799175",
  #     "itemAvailabilityStatus": "Available",
  #     "collectionGroupDesignation": "Open",
  #     "errorMessage": null
  #   }
  # ]
  def self.scsb_status(id)
    if id.empty?
      logger.error 'BackendController#scsb_status passed empty id'
      return nil
    end

    bibliographicId = id.to_s

    # Default - assume Columbia material
    institutionId = 'CUL'

    # But if it's a SCSB Id...
    if bibliographicId =~ /^SCSB\-/
      institutionId, dash, bibliographicId = bibliographicId.partition('-')
    end

    # LIBSYS-5508 - EMERGENCY - MARK ALL PARTNER MATERIAL AS UNAVAILABLE
    # return [] unless institutionId == 'CUL'
    
    cache_minutes = APP_CONFIG['scsb']['cache_minutes'] || 0
    expiry = cache_minutes * 60

    scsb_status = Rails.cache.fetch("scsb_status:#{id}", expires_in: expiry) do
      Recap::ScsbRest.get_bib_availability(bibliographicId, institutionId) || []
    end

    scsb_status
  end

  # The SCSB status API returns an array looks like this:
  # [
  #   {
  #     "itemBarcode": "CU18799175",
  #     "itemAvailabilityStatus": "Available",
  #     "collectionGroupDesignation": "Open",
  #     "errorMessage": null
  #   }
  # ]
  # but our code simplifies this into a simple hash, like this:
  # {
  #   "CU18799175"  =>  "Available"
  # }
  def self.scsb_availabilities(id)
    # we're reinstating services!  
    # let the true SCSB status be returned
    # # # LIBSYS-2892 - Suspend all Offsite ReCAP borrowing - it's all Unavailable
    # # return nil
    # # Pretend this id is unavailable (nil) unless we've
    # # reinstated the 'offsite' service.
    # reinstated = APP_CONFIG['reinstated_services'] || []
    # return nil unless reinstated.include?('offsite')
    
    if id.empty?
      logger.error 'BackendController#scsb_availabilities passed empty id'
      return nil
    end

    # NEXT-1660 - COVID - Don't offer offsite requests for Hathi ETAS
    etas_status = Covid.lookup_db_etas_status(id)
    return nil if (APP_CONFIG['hathi_etas'] && etas_status == 'deny')

    scsb_status = BackendController.scsb_status(id)

    availabilities = {}
    scsb_status.each do |item|
      availabilities[item['itemBarcode']] = item['itemAvailabilityStatus']
      # for testing...
      # availabilities[ item['itemBarcode'] ] = 'Unavailable'
    end
    availabilities
  end

  # Called with multiple ids, slash-separated:
  #   http://cliobeta.columbia.edu:3001/backend/offsite/1645852/766626
  # SCSB will give a status for each item (barcode) within the bib.
  # Simplify this, down to a hash map of just bib-to-status:
  #   { 123: 'available', 456: 'unavailable', 789: 'some_available'}
  # This code assumes that anything that's not "Available" shouild be
  # marked as "Unavailable".  We also have the option of marking some
  # material as "none", which won't get a green-check or red-X marking.
  # (Librarians also don't like the word "Unavailable" for material that
  # is not available, so they might not like the img alt text.)
  def offsite
    bibids = params['id'].to_s.split('/').collect(&:strip)
    statuses = {}

    bibids.each do |bib|
      availables = unavailables = 0
      begin
        scsb_status = BackendController.scsb_availabilities(bib)
      rescue => e
        statuses[bib] = 'unavailable'
        next
      end
      if scsb_status.present?
        scsb_status.each do |_barcode, availability|
          if availability == 'Available'
            availables += 1
          else
            unavailables += 1
          end
        end
      end

      bib_status = if availables > 0 && unavailables > 0
                     'some_available'
                   elsif availables > 0 && unavailables.zero?
                     'available'
                   else
                     'unavailable'
      end

      statuses[bib] = bib_status
    end
    # connection = get_oracle_connection()
    # holdings = Voyager::Request.simple_holdings_check(connection: connection, bibids: @bibids)
    render json: statuses

    # rescue => e
    #   # When we encounter an internal error,
    #   # what do we want our caller, CLIO, to see?
    #   # Probably nothing - just return empty JSON data, with HTTP 500
    #   render json: {}, status: :internal_server_error
    #   logger.error "Error calling BackendController#offsite(#{@bibids}): #{e}"
    # end
  end

  def holdings
    # LEGACY
    # LEGACY
    # LEGACY
    @id = params[:id]

    logger.error "Legacy BackendController#holdings called for id: #{@id}"

    unless @id =~ /^\d+$/
      logger.error "BackendController#holdings passed non-numeric id: #{@id}"
      render(body: nil) && return
    end

    backend_url = url_for_id(@id)
    begin
      json_holdings = backend_httpclient.get_content(backend_url)
      backend_holdings = JSON.parse(json_holdings)[@id]
    rescue HTTPClient::BadResponseError => ex
      logger.error "BackendController#holdings HTTPClient::BadResponseError URL: #{backend_url}  Exception: #{ex}"
      head(:bad_request) && return
    rescue HTTPClient::ReceiveTimeoutError => ex
      logger.error "HTTPClient::ReceiveTimeoutError URL: #{backend_url}"
      head(:bad_request) && return
    rescue => ex
      logger.error "BackendController error fetching holdings from #{backend_url}: #{ex.message}"
      head(:bad_request) && return
    end

    if backend_holdings.nil?
      logger.error "BackendController#holdings failed to fetch holdings for id: #{@id}"
      render(body: nil) && return
    end

    # data retrieved successfully!  render an html snippet.
    render 'backend/holdings', locals: { holdings: backend_holdings }, layout: false

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

  # https://clio-backend-dev.cul.columbia.edu/voyager/checked_out_items/ma3179
  def self.getCheckedOutItems(uni = '')
    unless uni.present?
      logger.error 'BackendController#getCheckedOutItems() called with no uni!'
      return []
    end

    # DEBUG
    # uni = 'ma3179'

    backend_url = url_for_id(uni, 'voyager/checked_out_items')

    begin
      json_results = backend_httpclient.get_content(backend_url)
      items = JSON.parse(json_results)
    rescue => ex
      logger.error "BackendController#getCheckedOutItems(#{uni}) #{ex} URL: #{backend_url}"
      return nil
    end

    items.map!(&:with_indifferent_access)
    items
  end

  #   def self.getCheckedOutBibs(uni = '')
  #     items = BackendController.getCheckedOutItems(uni) || []
  #
  #     bibs = []
  #     bibs_seen = []
  #     items.each do |item|
  #       bib_id = item[:bib_id]
  #       next if bibs_seen.include?(bib_id)
  #
  #       # For ReCAP Partner items, lookup bib details in Solr by barcode
  #       if item[:title].present?  && item[:title].include?('[RECAP]')
  #         barcode = item[:barcode]
  #         params = {q: 'barcode_txt:33433074813555'}
  #         response, documents = search_results(params)
  #         if documents.present? && documents.size > 0
  #
  # raise
  #           # item[:bib_id]    = row['BIB_ID'] || 0
  #           # item[:barcode]   = row['ITEM_BARCODE'] || 0
  #           # item[:author]    = documents.first.['AUTHOR'] || ''
  #           # item[:title]     = row['TITLE_BRIEF'] || ''
  #           # item[:author]    = row['AUTHOR'] || ''
  #           # item[:pub_name]  = row['PUBLISHER'] || ''
  #           # item[:pub_date]  = row['PUBLISHER_DATE'] || ''
  #           # item[:pub_place] = row['PUB_PLACE'] || ''
  #           # item[:isbn]      = row['ISBN'] || ''
  #           # item[:issn]      = row['ISSN'] || ''
  #         end
  #       end
  #
  #       bibs << item
  #       bibs_seen << bib_id
  #
  #     end
  #
  
  ###
  ###   CAIASOFT
  ###
  def self.caiasoft_itemstatus(barcode)

    if barcode.empty?
      logger.error 'BackendController#caiasoft_itemstatus passed empty id'
      return nil
    end

    cache_minutes = APP_CONFIG['caiasoft']['cache_minutes'] || 0
    expiry = cache_minutes * 60

    caiasoft_itemstatus = Rails.cache.fetch("caiasoft_itemstatus:#{barcode}", expires_in: expiry) do
      Clancy::CaiaSoft.get_itemstatus(barcode) || []
    end

    # caiasoft_itemstatus JSON:
    #   { "success":true, "error":"", "barcode":"0071298436",
    #     "status":"Out on Physical Retrieval on 08-27-2021" }
    caiasoft_itemstatus
  
  end
  
end
