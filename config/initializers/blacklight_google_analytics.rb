# Change to your Google Web id
BlacklightGoogleAnalytics.web_property_id = case Rails.env.to_s

# Narrow in - only test PROD
# when 'development'
#   'UA-30642217-2'
# when 'spectrum_dev', 'spectrum_test'
#   'UA-30642217-1'
# when 'test'
#   nil
# else
#   'UA-28923110-1'

when 'clio_prod'
  'UA-28923110-1'
else
  nil
end
