
# Block bad ips, bad user-agents.
# Rate-Limit all clients.

###
### BELOW DEFINITIONS USE APP_CONFIG
### THIS INITIALIZER MUST RUN AFTER: load_app_config.rb
###

# For docs and examples, see:
# https://github.com/kickstarter/rack-attack/blob/master/README.md
# http://www.kickstarter.com/backing-and-hacking/rack-attack-protection-from-abusive-clients

# Always allow requests from localhost (blocklist & throttles are skipped)
Rack::Attack.safelist('allow from localhost') do |req|
  '127.0.0.1' == req.ip || '::1' == req.ip
end

# Don't apply throttling to our own AJAX requests
Rack::Attack.safelist('allow from CLIO') do |req|
  '128.59.222.208' == req.ip
end

# FULLY WHITELISTED IPS/CIDRS - no throttling, no blocking, unlimited access
# - only add very specific trusted IPs/Subnets
APP_CONFIG['RACK_ATTACK_SAFE_LIST'].each do |goodguy|
  Rack::Attack.safelist_ip(goodguy)
end


# # Deny all access to IP Addresses in our bad-address list
# Rack::Attack.blocklist('block bad IPs') do |req|
#   APP_CONFIG['BAD_IP_LIST'].include? req.ip
# end

# New, simpler way to block, supports CIDR with no extra code
APP_CONFIG['BAD_IP_LIST'].each do |badguy|
  Rack::Attack.blocklist_ip(badguy)
end

# Deny all access to User Agents in our bad-agent list
Rack::Attack.blocklist('block bad User Agents') do |req|
  APP_CONFIG['BAD_USER_AGENT_LIST'].include? req.user_agent
end

# Filter by URL - specific params or path components may identify bad guys
Rack::Attack.blocklist('block bad URL substring') do |req|
  bad_url_substrings = APP_CONFIG['BAD_URL_SUBSTRING_LIST'] || []
  bad_url_substrings.any? { |bad_substring| req.url.match(bad_substring) }
end


# Deny all access to ANY "Java/1.x.y" User Agent - looking at the logs,
# these are predominately phishing or spidering.  If we find examples of
# legitimate use, we can fine-tune these rules.
Rack::Attack.blocklist('block all Java User Agents') do |req|
  req.user_agent && req.user_agent.start_with?('Java/')
end

# Rate-Limit to a certain number of requests per minute
Rack::Attack.throttle('req/minute', limit: APP_CONFIG['THROTTLE_LIMIT_PER_MINUTE'], period: 1.minute, &:ip)

# Rate-Limit to a certain number of requests per hour
Rack::Attack.throttle('req/hour', limit: APP_CONFIG['THROTTLE_LIMIT_PER_HOUR'], period: 1.hour, &:ip)

# Special tighter throttle rules for MARC XML requests, to dissuade bulk downloads
Rack::Attack.throttle('marcxml/hour', limit: 10, period: 1.hour) do |req|
  if req.path =~ /xml$/ and not req.ip =~ /128.59/
    req.ip
  end
end


# Use Fail2Ban to lock out penetration-testers based on defined rules.
#
# There's no legitimate reason for any of these patterns to show up,
# block the source IP on FIRST attempt, and for a long time.
Rack::Attack.blocklist('pentest') do |request|
  Rack::Attack::Fail2Ban.filter(
    # "pentest",                  # namespace for cache key
    request.ip, # count matching requests based on IP
    maxretry: 1, # allow up to X bad requests...
    findtime: 1.minutes, # to occur within Y minutes...
    bantime: 60.minutes
  ) do # and ban the IP address for Z minutes if exceeded

    # Remember to OR the different clauses below (with trailing ||)

    # # Fishing around for the MySQL Admin page
    # request.path =~ %r{scripts/setup.php} ||

    # Actually, any path which ends in any of these extensions is a pentest
    request.path =~ /\.(php|asp|aspx)$/ ||

      # Any WordPress access attempts
      # (wp-login, wp-admin, wp-signup, wp-content, wp-cache, etc.)
      request.path =~ %r{/wp-}
  end
end

# Lockout IP addresses that are abusing CLIO's email facility.
# After X requests in Y minutes, block all requests from that IP for Z hours.
Rack::Attack.blocklist('allow2ban email abusers') do |req|
  # `filter` returns false value if request is to your login page (but still
  # increments the count) so request below the limit are not blocked until
  # they hit the limit.  At that point, filter will return true and block.
  Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 10, findtime: 10.minute, bantime: 1.hour) do
    # The count for the IP is incremented if the return value is truthy.
    req.path == '/catalog/email' && req.post?
  end
end

# Rack::Attack.blocklist('fail2ban pentesters') do |req|
#   # `filter` returns truthy value if request fails, or if it's from a previously banned IP
#   # so the request is blocked
#   Rack::Attack::Fail2Ban.filter(req.ip, :maxretry => 3, :findtime => 10.minutes, :bantime => 5.minutes) do
#     # The count for the IP is incremented if the return value is truthy.
#     CGI.unescape(req.query_string) =~ %r{/etc/passwd}
#   end
# end

# Examples from documentation are pasted below, and commented-out.
#
# # Block requests containing '/etc/password' in the params.
# # After 3 blocked requests in 10 minutes, block all requests from that IP for 5 minutes.
# Rack::Attack.blocklist('fail2ban pentesters') do |req|
#   # `filter` returns truthy value if request fails, or if it's from a previously banned IP
#   # so the request is blocked
#   Rack::Attack::Fail2Ban.filter(req.ip, :maxretry => 3, :findtime => 10.minutes, :bantime => 5.minutes) do
#     # The count for the IP is incremented if the return value is truthy.
#     CGI.unescape(req.query_string) =~ %r{/etc/passwd}
#   end
# end
#
#
# # Throttle requests to 5 requests per second per ip
# Rack::Attack.throttle('req/ip', :limit => 5, :period => 1.second) do |req|
#   # If the return value is truthy, the cache key for the return value
#   # is incremented and compared with the limit. In this case:
#   #   "rack::attack:#{Time.now.to_i/1.second}:req/ip:#{req.ip}"
#   #
#   # If falsy, the cache key is neither incremented nor checked.
#
#   req.ip
# end
#
# # Throttle login attempts for a given email parameter to 6 reqs/minute
# # Return the email as a discriminator on POST /login requests
# Rack::Attack.throttle('logins/email', :limit => 6, :period => 60.seconds) do |req|
#   req.params['email'] if req.path == '/login' && req.post?
# end
#
#
# # Track requests from a special user agent
# Rack::Attack.track("special_agent") do |req|
#   req.user_agent == "SpecialAgent"
# end
#
# # Track it using ActiveSupport::Notification
# ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, req|
#   if req.env['rack.attack.matched'] == "special_agent" && req.env['rack.attack.match_type'] == :track
#     Rails.logger.info "special_agent: #{req.path}"
#     STATSD.increment("special_agent")
#   end
# end
#
#
# Rack::Attack.blocklisted_response = lambda do |env|
#   # Using 503 because it may make attacker think that they have successfully
#   # DOSed the site. Rack::Attack returns 401 for blocklists by default
#   [ 503, {}, ['Blocked']]
# end
#
# Rack::Attack.throttled_response = lambda do |env|
#   # name and other data about the matched throttle
#   body = [
#     env['rack.attack.matched'],
#     env['rack.attack.match_type'],
#     env['rack.attack.match_data']
#   ].inspect
#
#   # Using 503 because it may make attacker think that they have successfully
#   # DOSed the site. Rack::Attack returns 429 for throttling by default
#   [ 503, {}, [body]]
# end
#
#
#
# ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, req|
#   puts req.inspect
# end
