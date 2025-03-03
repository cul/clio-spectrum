# # Basic Rails client to the FOLIO Okapi endpoints
# #
# # Initially copied from:
# #     https://github.com/sul-dlss/folio_client
# #     "FolioClient is a Ruby gem that acts as a client to the
# #      RESTful HTTP APIs provided by the Folio ILS API"
#
# class Folio
#   module Okapi
#
#     DEFAULT_HEADERS = {
#       accept: 'application/json, text/plain',
#       content_type: 'application/json'
#     }.freeze
#
#     attr_reader :connection
#
#
#
#
#     # the base connection to the Folio API
#     def self.open_connection
#       folio_config = Folio::Config.get_folio_config
#
#       okapi_headers = {
#         'Accept': 'application/json, text/plain',
#         'Content-Type': 'application/json',
#         'X-Okapi-Tenant': folio_config['okapi_tenant']
#       }
#
#       @connection ||= Faraday.new(
#         url: folio_config['okapi_url'],
#         headers: okapi_headers,
#         request: { timeout: folio_config['okapi_timeout'] }
#       ) do |faraday|
#         faraday.use :cookie_jar, jar: self.cookie_jar
#         faraday.adapter Faraday.default_adapter
#       end
#     end
#
#     def self.cookie_jar
#       @cookie_jar ||= HTTP::CookieJar.new
#     end
#
#
#
#
#     # Send an authenticated get request
#     # @param path [String] the path to the Folio API request
#     # @param params [Hash] params to get to the API
#     def get(path, params = {})
#       response = with_token_refresh_when_unauthorized do
#         connection.get(path, params, { 'x-okapi-token': config.token })
#       end
#
#       UnexpectedResponse.call(response) unless response.success?
#
#       return nil if response.body.blank?
#
#       JSON.parse(response.body)
#     end
#
#     # Send an authenticated post request
#     # If the body is JSON, it will be automatically serialized
#     # @param path [String] the path to the Folio API request
#     # @param body [Object] body to post to the API as JSON
#     # rubocop:disable Metrics/MethodLength
#     def post(path, body = nil, content_type: 'application/json')
#       req_body = content_type == 'application/json' ? body&.to_json : body
#       response = with_token_refresh_when_unauthorized do
#         req_headers = {
#           'x-okapi-token': config.token,
#           'content-type': content_type
#         }
#         connection.post(path, req_body, req_headers)
#       end
#
#       UnexpectedResponse.call(response) unless response.success?
#
#       return nil if response.body.blank?
#
#       JSON.parse(response.body)
#     end
#     # rubocop:enable Metrics/MethodLength
#
#     # Send an authenticated put request
#     # If the body is JSON, it will be automatically serialized
#     # @param path [String] the path to the Folio API request
#     # @param body [Object] body to put to the API as JSON
#     # rubocop:disable Metrics/MethodLength
#     def put(path, body = nil, content_type: 'application/json')
#       req_body = content_type == 'application/json' ? body&.to_json : body
#       response = with_token_refresh_when_unauthorized do
#         req_headers = {
#           'x-okapi-token': config.token,
#           'content-type': content_type
#         }
#         connection.put(path, req_body, req_headers)
#       end
#
#       UnexpectedResponse.call(response) unless response.success?
#
#       return nil if response.body.blank?
#
#       JSON.parse(response.body)
#     end
#
#
#
#     private
#
#     # Wraps API operations to request new access token if expired.
#     # @yieldreturn response [Faraday::Response] the response to inspect
#     #
#     # @note You likely want to make sure you're wrapping a _single_ HTTP request in this
#     # method, because 1) all calls in the block will be retried from the top if there's
#     # an authN failure detected, and 2) only the response returned by the block will be
#     # inspected for authN failure.
#     # Related: consider that the client instance and its token will live across many
#     # invocations of the FolioClient methods once the client is configured by a consuming application,
#     # since this class is a Singleton.  Thus, a token may expire between any two calls (i.e. it
#     # isn't necessary for a set of operations to collectively take longer than the token lifetime for
#     # expiry to fall in the middle of that related set of HTTP calls).
#     def with_token_refresh_when_unauthorized
#       response = yield
#
#       # if unauthorized, token has likely expired. try to get a new token and then retry the same request(s).
#       if [401, 403].include?(response.status)
#         force_token_refresh!
#         response = yield
#       end
#
#       response
#     end
#
#   end
#
# end
#
