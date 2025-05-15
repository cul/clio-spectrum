# Wrapper around Stanford FolioClient
module Folio
  class Client
    
    attr_reader :conn
    
    def initialize
      @conn ||= Culfolio::Client.open_connection
    end
  
    def self.get_folio_config
      # app_config should have a FOLIO stanza
      folio_config = APP_CONFIG['folio']
      raise "Cannot find 'folio' config in APP_CONFIG!" if folio_config.blank?
      
      # Return the entire stanza - whatever it holds
      return folio_config
    end
  
    def self.open_connection
      folio_config = get_folio_config
      @conn = FolioClient.configure(
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
      return @conn
    end
    
    # Mimic postman:
    #   {{baseUrl}}/users?query=(username=="sam119*" )
    def self.get_user_by_username(username)
      @conn ||= open_connection
      query = '(username == "' + username + '")'
      json_response = @conn.get("/users?query=#{query}")
      first_user = json_response["users"].first
      return first_user
    end

    # /circulation/loans?query=(userId==5a05ac92-5512-5f1e-8198-31bcb9bf3397) sortby id
    def self.get_loans_by_user_uuid(user_uuid)
      @conn ||= open_connection
      query = '(status="Open") and (userId == ' + user_uuid + ')'
      json_response = @conn.get("/circulation/loans?query=#{query}")
      all_open_loans = json_response["loans"]
      return all_open_loans
    end
    
    # /circulation/loans?query=(userId==5a05ac92-5512-5f1e-8198-31bcb9bf3397) sortby id
    def self.get_requests_by_user_uuid(user_uuid)
      @conn ||= open_connection
      query = '(status="Open - Not yet filled") and (requesterId == ' + user_uuid + ')'
      json_response = @conn.get("/circulation/requests?query=#{query}")
      all_open_requests = json_response["requests"]
      return all_open_requests
    end
    
    
    
  end

end


