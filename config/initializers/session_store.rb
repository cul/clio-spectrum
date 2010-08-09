# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_new_books_session',
  :secret      => '1d4c165a5dbead576fb5703dd43dc329e9e36e3fc1ccc3eccf8d75031412f475e222b8b366db7be0bf69936d167fe52fdcde317d9cd8223878c5cdaaa0a88591'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
