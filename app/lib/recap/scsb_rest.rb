
module Recap
  class ScsbRest
    attr_reader :conn, :scsb_args

    def self.get_scsb_rest_args
      app_config_key = 'rest_connection_details'
      scsb_args = APP_CONFIG['scsb'][app_config_key]
      raise "Cannot find #{app_config_key} in APP_CONFIG!" if scsb_args.blank?
      scsb_args = HashWithIndifferentAccess.new(scsb_args)

      [:api_key, :url, :item_availability_path].each do |key|
        raise "SCSB config needs value for '#{key}'" unless scsb_args.key?(key)
      end

      @scsb_args = scsb_args
    end

    def self.open_connection(url = nil)
      if @conn
        return @conn if url.nil? || (@conn.url_prefix.to_s == url)
      end

      get_scsb_rest_args
      url ||= @scsb_args[:url]
      Rails.logger.debug "- opening new connection to #{url}"
      @conn = Faraday.new(url: url)
      raise "Faraday.new(#{url}) failed!" unless @conn

      @conn.headers['Content-Type'] = 'application/json'
      @conn.headers['api_key'] = @scsb_args[:api_key]

      @conn
    end

    # NOTE: Currently bibAvailabilityStatus and itemAvailabilityStatus
    # return the same response format:
    # [
    #   {
    #     "itemBarcode": "CU10104704",
    #     "itemAvailabilityStatus": "Available",
    #     "errorMessage": null
    #   },
    #   {
    #     "itemBarcode": "CU10104712",
    #     "itemAvailabilityStatus": "Available",
    #     "errorMessage": null
    #   },
    #   ...
    # ]
    # But the APIs are still under active development.  Response
    # format may diverge in the future.

    # Called like this:
    # availability = Recap::ScsbRest.get_item_availability(barcodes)
    def self.get_item_availability(barcodes = [], conn = nil)
      raise 'Recap::ScsbRest.get_item_availability() got blank barcodes' if barcodes.blank?
      Rails.logger.debug "- get_item_availability(#{barcodes})"

      conn ||= open_connection
      raise "get_item_availability() bad connection [#{conn.inspect}]" unless conn

      get_scsb_rest_args
      path = @scsb_args[:item_availability_path]
      params = {
        barcodes: barcodes
      }

      response = conn.post path, params.to_json
      if response.status != 200
        # Raise or just log error?
        Rails.logger.error "SCSB ERROR:  API response status #{response.status}"
        Rails.logger.error 'SCSB ERROR DETAILS: ' + response.body
        return ''
      end

      # parse returned array of item-info hashes into simple barcode->status hash
      response_data = JSON.parse(response.body).with_indifferent_access
      availabilities = {}
      response_data.each do |item|
        availabilities[item['itemBarcode']] = item['itemAvailabilityStatus']
      end
      availabilities
    end

    # The SCSB status API returns an array looks like this:
    # [
    #   {
    #     "itemBarcode": "CU18799175",
    #     "itemAvailabilityStatus": "Available",
    #     "collectionGroupDesignation": "Open",
    #     "errorMessage": null
    #   },
    #   {
    #      ...
    #   },
    #   ...
    # ]
    #
    # Special case - BIB NOT FOUND - Response Code 200, Response Body:
    # [
    #   {
    #     "itemBarcode": "",
    #     "itemAvailabilityStatus": null,
    #     "collectionGroupDesignation": "Open",
    #     "errorMessage": "Bib Id doesn't exist in SCSB database."
    #   }
    # ]
    def self.get_bib_availability(bibliographicId = nil, institutionId = nil, conn = nil)
      raise 'Recap::ScsbRest.get_bib_availability() got nil bibliographicId' if bibliographicId.blank?
      raise 'Recap::ScsbRest.get_bib_availability() got nil institutionId' if institutionId.blank?
      Rails.logger.debug "- get_bib_availability(#{bibliographicId}, #{institutionId})"

      conn ||= open_connection
      raise "get_bib_availability() bad connection [#{conn.inspect}]" unless conn

      get_scsb_rest_args
      path = @scsb_args[:bib_availability_path]
      params = {
        bibliographicId: bibliographicId,
        institutionId:   institutionId
      }
      # Noisy debugging when needed
      Rails.logger.debug "get_bib_availability(#{bibliographicId}) calling SCSB REST API with params #{params.inspect}"
      response = conn.post path, params.to_json
      Rails.logger.debug "SCSB response status: #{response.status}"
      Rails.logger.debug "SCSB response body: #{response.body}"

      if response.status != 200
        # Raise or just log error?
        Rails.logger.error "SCSB ERROR:  API response status #{response.status}"
        Rails.logger.error 'SCSB ERROR DETAILS: ' + response.body
        return nil
      end

      # parse returned array of item-info hashes into simple barcode->status hash
      response_data = []
      begin
        response_data = JSON.parse(response.body)
      rescue => ex
        Rails.logger.error "SCSB ERROR:  JSON.parse(response.body) #{ex.message}"
        Rails.logger.error 'SCSB ERROR DETAILS: ' + response.body
        return nil
      end

      response_data

      # availabilities = Hash.new
      # response_data.each do |item|
      #   availabilities[ item['itemBarcode'] ] = item['itemAvailabilityStatus']
      #   # for testing...
      #   # availabilities[ item['itemBarcode'] ] = 'Unavailable'
      # end
      # return availabilities
    end

    # UNUSED
    def self.get_patron_information(patron_barcode = nil, institution_id = nil, conn = nil)
      raise # UNUSED
      raise 'Recap::ScsbRest.get_patron_information() got blank patron_barcode' if patron_barcode.blank?
      raise 'Recap::ScsbRest.get_patron_information() got blank institution_id' if institution_id.blank?
      Rails.logger.debug "- get_patron_information(#{patron_barcode}, #{institution_id})"

      conn ||= open_connection
      raise "get_bib_availability() bad connection [#{conn.inspect}]" unless conn

      get_scsb_rest_args
      path = @scsb_args[:patron_information_path]
      params = {
        patronIdentifier:      patron_barcode,
        itemOwningInstitution: institution_id
      }
      response = conn.post path, params.to_json

      if response.status != 200
        # Raise or just log error?
        Rails.logger.error "SCSB ERROR:  API response status #{response.status}"
        Rails.logger.error 'SCSB ERROR DETAILS: ' + response.body
      end

      # Rails.logger.debug "response.body=\n#{response.body}"
      patron_information_hash = JSON.parse(response.body).with_indifferent_access
      # Just return the full hash, let the caller pull out what they want
      patron_information_hash
    end

    def self.request_item(params, conn = nil)
      # Do we want to check params to see if what we need is in there?
      Rails.logger.debug "- request_item(#{params.inspect})"

      conn ||= open_connection
      raise "request_item() bad connection [#{conn.inspect}]" unless conn

      get_scsb_rest_args
      path = @scsb_args[:request_item_path]
      response = conn.post path, params.to_json

      if response.status != 200
        # A SCSB-side error might look something like this:
        # response.status: 500
        # response.body: {
        #   "timestamp":1502041272960,
        #   "status":500,
        #   "error":"Internal Server Error",
        #   "exception":"org.springframework.web.client.ResourceAccessException",
        #   "message":"I/O error on POST request for \"http://172.31.4.217:9095/requestItem/validateItemRequest\": Connection refused; nested exception is java.net.ConnectException: Connection refused","path":"/requestItem/requestItem"
        # }

        # Log error, trust caller to look into response hash to do the right thing
        Rails.logger.error "SCSB ERROR:  API response status #{response.status}"
        Rails.logger.error 'SCSB ERROR DETAILS: ' + response.body
      end

      # Rails.logger.debug "response.body=\n#{response.body}"
      response_hash = JSON.parse(response.body).with_indifferent_access
      # Just return the full hash, let the caller pull out what they want
      response_hash
    end
  end
end
