#
# Wrapper around Stanford FolioClient
# 
# Get a FolioClient with either of:
#   folio_client = Folio::Client.new()
#   folio_client = Folio::Client.folio_client
# 
# Call the helper methods defined below:
#   Folio::Client.get_user_by_username('sam119')
# 
# Or make direct FOLIO API calls yourself:
#   location_json = Folio::Client.folio_client.get('/locations')
# 
module Folio
  class Client
    
    attr_reader :folio_client
    
    def initialize
      @folio_client ||= Folio::Client.folio_client
    end
  
    def self.get_folio_config
      # app_config should have a FOLIO stanza
      folio_config = APP_CONFIG['folio']
      raise "Cannot find 'folio' config in APP_CONFIG!" if folio_config.blank?
      
      # Return the entire stanza - whatever it holds
      return folio_config
    end
  
    def self.folio_client
      folio_config = get_folio_config
      @folio_client = FolioClient.configure(
        url: folio_config['okapi_url'],
        login_params: { 
          username: folio_config['okapi_username'], 
          password: folio_config['okapi_password']
        },
        okapi_headers: { 
          'X-Okapi-Tenant': folio_config['okapi_tenant'], 
          'User-Agent': 'FolioApiClient'
        }
      )
      return @folio_client
    end
    
    # Mimic postman:
    #   {{baseUrl}}/users?query=(username=="sam119*" )
    def self.get_user_by_username(username)
      @folio_client ||= folio_client
      query = '(username == "' + username + '")'
      json_response = @folio_client.get("/users?query=#{query}")
      first_user = json_response["users"].first
      return first_user
    end

    # /circulation/loans?query=(userId==5a05ac92-5512-5f1e-8198-31bcb9bf3397) sortby id
    def self.get_loans_by_user_id(user_id)
      @folio_client ||= folio_client
      query = '(status="Open") and (userId == ' + user_id + ')'
      json_response = @folio_client.get("/circulation/loans?query=#{query}&limit=500")
      all_open_loans = json_response["loans"]
      return all_open_loans
    end
    
    # /circulation/loans?query=(userId==5a05ac92-5512-5f1e-8198-31bcb9bf3397) sortby id
    def self.get_requests_by_user_id(user_id)
      @folio_client ||= folio_client
      query = '(status="Open - Not yet filled") and (requesterId == ' + user_id + ')'
      json_response = @folio_client.get("/circulation/requests?query=#{query}")
      all_open_requests = json_response["requests"]
      return all_open_requests
    end

    # FOLIO has two kinds of blocks - automated and manual
    #  {{baseUrl}}/automated-patron-blocks/04354620-5852-54e7-93e5-67b8d374528c
    #  {{baseUrl}}/manualblocks?limit=10000&query=(userId==74b140b4-636a-5476-8312-e0d1d4eaaad5)
    # Fetch both, parse each appropriately, sort/uniq the list, return list of string messages
    def self.get_blocks_by_user_id(user_id)
      @folio_client ||= folio_client

      all_blocks = []

      # Automated
      json_response = @folio_client.get("/automated-patron-blocks/#{user_id}")
      automated_blocks = json_response["automatedPatronBlocks"]
      automated_blocks.each do |block|
        block_message = block["message"]
        all_blocks << block_message unless all_blocks.include?(block_message)
      end

      # Manual
      query = '(userId == ' + user_id + ')'
      json_response = @folio_client.get("/manualblocks?query=#{query}&limit=500")
      manual_blocks = json_response["manualblocks"]
      manual_blocks.each do |block|
        block_message = block["patronMessage"]
        all_blocks << block_message unless all_blocks.include?(block_message)
      end

      return all_blocks
    end

    
    def self.renew_by_id(user_id:, item_id:)
      @folio_client ||= folio_client
      # It's important to keep these as string keys, not symbol keys,
      # or FolioClient will misinterpret them as keyword arguments
      params = { "itemId" => item_id, "userId" => user_id }

      # the error message, if any, is found in different places for different problems
      error_message = nil
      
      begin
        renewal_status = @folio_client.post("/circulation/renew-by-id", params)
      rescue FolioClient::ValidationError => ex
        message = ex.message.sub(/There was a validation problem with the request: /, '')
        json = JSON.parse(message)
        if json and json["errors"]
          error_message = json["errors"].first["message"]
        else
          error_message = ex.message
        end
      rescue => ex
        error_message = ex.message
      end
      
      # If any error-message was set in the rescues above, raise an exception for the caller
      raise error_message if error_message
      
      # A quiet return is a successful renewal
      return
    end


    def self.delete_request(request_id:)
      @folio_client ||= folio_client

      path = "/circulation/requests/#{request_id}"

      # Deletes aren't yet handled natively by SUL folio_client gem.
      # And, with_token_refresh_when_unauthorized() is a private method.
      # Do everything ourselves, step by step, using the Faraday connection.
      login_params = FolioClient.config.login_params
      connection = FolioClient.connection
      token = FolioClient::Authenticator.token(login_params, connection)
      response = connection.delete(path, nil, { 'x-okapi-token': token })
    end
  
    # Retrieve a single FOLIO Instance JSON record for a given Voyager Bib ID
    #   {{baseUrl}}/search/instances?query=(hrid="123")&limit=1
    def self.get_instance_by_hrid(hrid)
      query = '(hrid="' + hrid + '")'
      path = "/search/instances?query=#{query}&limit=1"
      @folio_client ||= folio_client
      folio_response = @folio_client.get(path)
      instances = folio_response['instances']
      if instances.present?
        return instances.first
      else
        return {}
      end
    end
    
    
    # Retrieve a list of FOLIO Holdings JSON records for a given FOLIO Instance UUID
    #   {{baseUrl}}/holdings-storage/holdings?query=(instanceId == "c3cf979d-3562-5cce-b130-88d36f4a99c6")
    def self.get_holdings_by_instance(instance_uuid)
      query = '(instanceId=="' + instance_uuid + '")'
      path = "/holdings-storage/holdings?query=#{query}"
      @folio_client ||= folio_client
      folio_response = @folio_client.get(path)
      holdings = folio_response['holdingsRecords']
      # error?
      return {} unless holdings
      # success!
      return holdings
    end

    # Retrieve a list of all FOLIO Item JSON records for a given FOLIO Holding UUID
    #   {{baseUrl}}/inventory/items-by-holdings-id?query=(holdingsRecordId=="d91b5d2a-d4f6-57f6-9108-35965f9fbf32")
    def self.get_items_by_holding(holding_uuid)
      query = '(holdingsRecordId=="' + holding_uuid + '")'
      path = "/inventory/items-by-holdings-id?query=#{query}"
      @folio_client ||= folio_client
      folio_response = @folio_client.get(path)
      items = folio_response['items']
      # error?
      return {} unless items
      # success!
      return items
    end




    # Replacement for Voyager-based circ_status
    # Given a bib id (e.g., 123),
    # Return a structure of availability statuses,
    #   bib-id (NOT uuid) / holdings-uuid / item-uuid / status-data
    # status-data so far is the item-status and date - but this can 
    # be expanded as needed
    # { 123: {
    #     456: {
    #       789: {
    #         "itemStatus":     "Available",
    #         "itemStatusDate": "2025-05-15T06:45:11.188+00:00"
    #       }
    #     }
    # }
    # We'll build this up in a series of item-specific API calls, because 
    # FOLIO shortcut API endpoints often don't return clean raw data,
    # only pre-processed opinionated display-oriented fields.
    # Docs: https://docs.folio.org/docs/platform-essentials/item-status/itemstatus/
    def self.get_availability(bib_id)
      availability = {}

      # First, fetch the FOLIO Instance
      instance = self.get_instance_by_hrid(bib_id)
      # Our instance-level key will be the MARC 001 Bib ID - NOT the FOLIO UUID
      availability[bib_id] = {}

      # Next, get the list of holdings
      holdings = self.get_holdings_by_instance(instance['id'])
      
      holdings.each do |holding|
        holding_id = holding['id']
        availability[bib_id][holding_id] = {}
        
        items = self.get_items_by_holding(holding_id)
        items.each do |item|
          item_id = item['id']
          availability[bib_id][holding_id][item_id] = {}

          # Now, finally, gather the data elements we care about
          availability[bib_id][holding_id][item_id]['itemStatus'] = item['status']['name']
          availability[bib_id][holding_id][item_id]['itemStatusDate'] = item['status']['date']
        end

      end
      
      return availability
    end
    
  end

end


