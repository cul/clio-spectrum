
Recaptcha.configure do |config|
  config.site_key = APP_CONFIG['recaptcha_site_key'] || 'invalid'
  config.secret_key = APP_CONFIG['recaptcha_secret_key'] || 'invalid'
  # Uncomment the following line if you are using a proxy server:
  # config.proxy = 'http://myproxy.com.au:8080'
end
