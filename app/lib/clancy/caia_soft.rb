module Clancy
    class CaiaSoft

    attr_reader :conn, :caiasoft_config

    def self.get_caiasoft_config
      caiasoft_config = APP_CONFIG['caiasoft']
      raise "Cannot find #{app_config_key} in APP_CONFIG!" if caiasoft_config.blank?
      caiasoft_config = HashWithIndifferentAccess.new(caiasoft_config)

      [:api_key, :api_url, :itemstatus_path].each do |key|
        raise "caiasoft config needs value for '#{key}'" unless caiasoft_config.key?(key)
      end

      @caiasoft_config = caiasoft_config
    end

    def self.open_connection(url = nil)
      # Re-use an existing connection?
      # How do we detect if this connection object has gone invalid for any reason?
      if @conn
        return @conn if url.nil? || (@conn.url_prefix.to_s == url)
      end

      get_caiasoft_config
      url ||= @caiasoft_config[:api_url]
      Rails.logger.debug "- opening new connection to #{url}"
      @conn = Faraday.new(url: url)
      raise "Faraday.new(#{url}) failed!" unless @conn

      @conn.headers['Content-Type'] = 'application/json'
      @conn.headers['X-API-Key'] = @caiasoft_config[:api_key]

      @conn
    end
  
  
    # Documentation at:   https://portal.caiasoft.com/apiguide.php
    # REST API endpoint:  /itemstatus
    # Details:  Item Status
    # URL:  https://yourlibrary.caiasoft.com/api/itemstatus/v1/{barcode}
    #
    # Example call URL:
    #   https://clancy.caiasoft.com/api/itemstatus/v1/0071298436
    # Return JSON:
    #   { "success":true, "error":"", "barcode":"0071298436",
    #     "status":"Out on Physical Retrieval on 08-27-2021" }
    #
    def self.get_itemstatus(barcode, conn = nil)
        raise 'CaiaSoft.get_itemstatus() got blank barcode' if barcode.blank?
        Rails.logger.debug "- CaiaSoft.get_itemstatus(#{barcode})"

        conn ||= open_connection
        raise "CaiaSoft.get_itemstatus() bad connection [#{conn.inspect}]" unless conn

        get_caiasoft_config
        path = @caiasoft_config[:itemstatus_path] + barcode.to_s
        response = conn.get path

        if response.status != 200
          # Raise or just log error?
          Rails.logger.error "CaiaSoft.get_itemstatus error:  API response status #{response.status}"
          Rails.logger.error 'CaiaSoft.get_itemstatus error details: ' + response.body
          return ''
        end

        # parse returned array of item-info hashes into simple barcode->status hash
        caiasoft_itemstatus = JSON.parse(response.body).with_indifferent_access

        # # TESTING
        # caiasoft_itemstatus[:status] = 'Item In at Rest' if barcode == '0071799010'

        caiasoft_itemstatus
      end

  end
end
