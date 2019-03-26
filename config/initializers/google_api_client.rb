
require 'google/apis/core/base_service'

Google::Apis.logger = Logger.new(STDERR)
Google::Apis.logger.level = APP_CONFIG['google']['log_level'] || Logger::INFO

Google::Apis::RequestOptions.default.retries = APP_CONFIG['google']['api_retries'] || 2


