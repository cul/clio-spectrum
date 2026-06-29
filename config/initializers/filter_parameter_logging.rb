# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [
  # use a regex to catch case-insensitive substring patterns
  /passw|secret|token|_key|crypt|salt|certificate|otp|ssn|access_key|credential/i
  
]
