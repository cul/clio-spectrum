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
      json_response = @folio_client.get("/circulation/loans?query=#{query}")
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

    
  end

end


