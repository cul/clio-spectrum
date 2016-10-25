
Recaptcha.configure do |config|
  config.public_key  = APP_CONFIG['recaptcha_public_key']
  config.private_key = APP_CONFIG['recaptcha_private_key']
  # Uncomment the following line if you are using a proxy server:
  # config.proxy = 'http://myproxy.com.au:8080'
end

