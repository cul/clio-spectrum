
require 'google/apis/core/base_service'

google_config = APP_CONFIG['google'] || {}

Google::Apis.logger = Logger.new(STDERR)
Google::Apis.logger.level = google_config['log_level'] || Logger::INFO

Google::Apis::RequestOptions.default.retries = google_config['api_retries'] || 2


