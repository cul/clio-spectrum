
require 'google/apis/core/base_service'

Google::Apis::RequestOptions.default.retries = APP_CONFIG['google']['api_retries'] || 2


