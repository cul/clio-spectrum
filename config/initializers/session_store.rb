# Be sure to restart your server when you modify this file.

# 3/2014 - we're seeing a handful of ActionDispatch::Cookies::CookieOverflow
# errors in production.
# The session holds the full set of search params (all facet values), plus the
# previous_url.  Should we revert to ActiveRecord?  Or try file-store?

case Rails.env.to_s

  # Localhost development and test use SQLite,
  # which can't handle Sessions plus AJAX sessions:
  #     SQLite3::BusyException: database is locked
when 'development'
  # Clio::Application.config.session_store :cookie_store, key: '_clio_session'
  Clio::Application.config.session_store :active_record_store, key: '_clio_session', expire_after: 14.days
when 'test'
  Clio::Application.config.session_store :cookie_store, key: '_clio_session', expire_after: 14.days

  # Any server-deployed environment uses MySQL,
  # which doesn't run into this locked-database issue
else
  Clio::Application.config.session_store :active_record_store, key: '_clio_session', expire_after: 14.days
end

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
