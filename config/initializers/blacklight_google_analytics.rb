# Change to your Google Web id 
BlacklightGoogleAnalytics.web_property_id = case Rails.env.to_s
when 'development', 'spectrum_dev', 'spectrum_test'
  'UA-30642217-1' 
when  'test'
  nil
else
  'UA-28923110-1'
end
