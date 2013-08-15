
# Block bad ips, bad user-agents.
# Rate-Limit all clients.

### 
### BELOW DEFINITIONS USE APP_CONFIG
### THIS INITIALIZER MUST RUN AFTER: load_app_config.rb
###

# For docs and examples, see:
# https://github.com/kickstarter/rack-attack/blob/master/README.md
# http://www.kickstarter.com/backing-and-hacking/rack-attack-protection-from-abusive-clients


# Always allow requests from localhost (blacklist & throttles are skipped)
Rack::Attack.whitelist('allow from localhost') do |req|
  '127.0.0.1' == req.ip
end

# Don't apply throttling to our own AJAX requests
Rack::Attack.whitelist('allow from CLIO') do |req|
  '128.59.222.208' == req.ip
end

# Deny all access to IP Addresses in our bad-address list
Rack::Attack.blacklist('block bad IPs') do |req|
  APP_CONFIG['BAD_IP_LIST'].include? req.ip
end

# Deny all access to User Agents in our bad-agent list
Rack::Attack.blacklist('block bad User Agents') do |req|
  APP_CONFIG['BAD_USER_AGENT_LIST'].include? req.user_agent
end

# Deny all access to ANY "Java/1.x.y" User Agent - looking at the logs,
# these are predominately phishing or spidering.  If we find examples of
# legitimate use, we can fine-tune these rules.
Rack::Attack.blacklist('block all Java User Agents') do |req|
  req.user_agent.start_with?('Java/1.')
end

# Rate-Limit to a certain number of requests per minute
Rack::Attack.throttle('req/ip', :limit => APP_CONFIG['THROTTLE_LIMIT_PER_MINUTE'], :period => 1.minute) do |req|
  req.ip
end

# Rate-Limit to a certain number of requests per hour
Rack::Attack.throttle('req/ip', :limit => APP_CONFIG['THROTTLE_LIMIT_PER_HOUR'], :period => 1.hour) do |req|
  req.ip
end



# Rack::Attack.blacklist('fail2ban pentesters') do |req|
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
# Rack::Attack.blacklist('fail2ban pentesters') do |req|
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
# Rack::Attack.blacklisted_response = lambda do |env|
#   # Using 503 because it may make attacker think that they have successfully
#   # DOSed the site. Rack::Attack returns 401 for blacklists by default
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
