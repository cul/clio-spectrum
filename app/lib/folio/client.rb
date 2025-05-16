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
      @folio_client ||= Culfolio::Client.folio_client
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
    
    
    
  end

end


