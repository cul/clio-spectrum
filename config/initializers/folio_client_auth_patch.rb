# frozen_string_literal: true

# config/initializers/folio_client_auth_patch.rb
#
# Backports the authentication behavior of folio_client >= 0.21 onto
# folio_client 0.15.0, which we are pinned to by Ruby 2.7.
# DELETE THIS FILE if/when the gem is upgraded.
#
# Stock 0.15.0 behavior (the problem):
#   - logs in via the deprecated /authn/login endpoint
#   - sends the token in an X-Okapi-Token header
#   - re-logs-in ONLY when FOLIO answers 401. Current FOLIO can answer 403
#     for an expired token, so a process keeps using a dead token until it
#     is restarted. (Upstream fixed this in 0.21.0 by retrying on 401 + 403.)
#
# Patched behavior (matches current upstream, plus proactive refresh):
#   - logs in via /authn/login-with-expiry and reads the folioAccessToken cookie
#   - sends the token as a Cookie header (optionally also X-Okapi-Token, see below)
#   - re-logs-in shortly BEFORE the token expires (from the cookie's Max-Age)
#   - also re-logs-in and retries once on a 401 or 403 response
#   - adds FolioClient.delete and FolioClient.force_token_refresh!
#
# The X-Okapi-Tenant header (okapi_headers in FolioClient.configure) is still
# required by FOLIO and is still sent by the current gem; nothing changes there.

require 'json'
require 'time'
require 'folio_client'

if FolioClient::VERSION != '0.15.0'
  raise "#{__FILE__} was written for folio_client 0.15.0, but #{FolioClient::VERSION} " \
        'is loaded. Newer versions handle auth themselves; review before keeping this patch.'
end

module FolioClientAuthPatch
  LOGIN_PATH = '/authn/login-with-expiry'

  # Re-login this many seconds before FOLIO's stated expiry.
  REFRESH_MARGIN = 60

  # Assumed token lifetime (seconds) if FOLIO doesn't tell us one.
  FALLBACK_LIFETIME = 300

  # Responses that trigger one re-login and retry.
  RETRY_STATUSES = [401, 403].freeze

  # Also send the token in the legacy X-Okapi-Token header.
  # Current upstream sends the cookie only, so leave this false unless
  # testing shows your FOLIO rejects cookie-only requests.
  SEND_LEGACY_TOKEN_HEADER = true

  LOCK = Mutex.new

  # Same signatures and return values as folio_client 0.15.0

  def get(path, params = {})
    response = with_token_refresh_when_unauthorized do
      connection.get(path, params, folio_auth_headers)
    end
    folio_parse(response)
  end

  def post(path, body = nil, content_type: 'application/json')
    req_body = content_type == 'application/json' ? body&.to_json : body
    response = with_token_refresh_when_unauthorized do
      connection.post(path, req_body, folio_auth_headers.merge('Content-Type' => content_type))
    end
    folio_parse(response)
  end

  def put(path, body = nil, content_type: 'application/json')
    req_body = content_type == 'application/json' ? body&.to_json : body
    response = with_token_refresh_when_unauthorized do
      connection.put(path, req_body, folio_auth_headers.merge('Content-Type' => content_type))
    end
    folio_parse(response)
  end

  # New: not present in 0.15.0. Returns parsed JSON body, or nil for an
  # empty body (e.g. 204). Raises a FolioClient error on failure.
  def delete(path)
    response = with_token_refresh_when_unauthorized do
      connection.delete(path, nil, folio_auth_headers)
    end
    folio_parse(response)
  end

  # Log in now and store a fresh access token, unconditionally.
  def force_token_refresh!
    folio_refresh_token(force: true)
  end

  private

  # Logs in under a lock. With force: false, a caller that waited on the
  # lock skips the login if another thread already refreshed the token.
  def folio_refresh_token(force:)
    LOCK.synchronize do
      return @folio_access_token if !force && folio_token_fresh?

      # Content-Type is already a connection default in 0.15.0; stated
      # explicitly here so the login doesn't depend on that.
      response = connection.post(LOGIN_PATH, config.login_params.to_json,
                                 'Content-Type' => 'application/json')
      FolioClient::UnexpectedResponse.call(response) unless response.success?

      # Faraday normally joins multiple Set-Cookie headers into one String
      # with ", "; coerce in case some adapter returns an Array instead.
      set_cookie = Array(response.headers['set-cookie']).join(', ')
      token = set_cookie[/folioAccessToken=([^;,\s]+)/, 1]
      unless token
        raise FolioClient::UnauthorizedError,
              "FOLIO login returned #{response.status} but no folioAccessToken cookie"
      end

      lifetime = folio_token_lifetime(set_cookie, response.body)
      @folio_access_token = token
      @folio_refresh_at = Time.now + [lifetime - REFRESH_MARGIN, lifetime / 2].max
      config.token = token # keep 0.15.0's own field in sync

      folio_log(:info, "obtained new FOLIO access token (lifetime #{lifetime}s)")
      token
    end
  end

  def folio_token_fresh?
    !@folio_access_token.nil? && !@folio_refresh_at.nil? && Time.now < @folio_refresh_at
  end

  # Headers for an authenticated request; refreshes first if the token
  # is missing or about to expire.
  def folio_auth_headers
    folio_refresh_token(force: false) unless folio_token_fresh?

    headers = { 'Cookie' => "folioAccessToken=#{@folio_access_token}" }
    headers['X-Okapi-Token'] = @folio_access_token if SEND_LEGACY_TOKEN_HEADER
    headers
  end

  # Overrides 0.15.0's version, which only handled 401.
  # The block must make exactly one HTTP call; it is re-run on retry.
  def with_token_refresh_when_unauthorized
    response = yield
    return response unless RETRY_STATUSES.include?(response.status)

    folio_log(:warn, "FOLIO returned #{response.status}; refreshing token and retrying once")
    folio_refresh_token(force: true)
    yield
  end

  def folio_parse(response)
    FolioClient::UnexpectedResponse.call(response) unless response.success?
    return nil if response.body.blank?

    JSON.parse(response.body)
  end

  # Seconds until the access token expires. Prefers the cookie's Max-Age
  # (relative, so immune to clock skew), then the accessTokenExpiration
  # field of the login response body, then FALLBACK_LIFETIME.
  def folio_token_lifetime(set_cookie, body)
    # Attributes of the folioAccessToken cookie only: stop at the next
    # folio*Token cookie so we never read folioRefreshToken's (much longer) Max-Age.
    attrs = set_cookie[/folioAccessToken=.*?(?=,\s*folio\w+=|\z)/m].to_s
    max_age = attrs[/Max-Age=(\d+)/i, 1].to_i
    return max_age if max_age.positive?

    begin
      expires = JSON.parse(body.to_s)['accessTokenExpiration']
      seconds = (Time.iso8601(expires) - Time.now).to_i if expires
      return seconds if seconds&.positive?
    rescue StandardError
      # fall through to the default
    end

    FALLBACK_LIFETIME
  end

  def folio_log(level, message)
    Rails.logger&.public_send(level, "FolioClientAuthPatch: #{message}") if defined?(Rails)
  end
end

FolioClient.prepend(FolioClientAuthPatch)

# 0.15.0 delegates an explicit list of class methods to the singleton
# instance; add the two new ones so FolioClient.delete(...) works.
FolioClient.singleton_class.delegate :delete, :force_token_refresh!, to: :instance
