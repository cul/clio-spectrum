
class Folio
  module Edge


    def self.open_connection(url = nil)
      # Re-use an existing connection?
      # How do we detect if this connection object has gone invalid for any reason?
      if @conn
        return @conn if url.nil? || (@conn.url_prefix.to_s == url)
      end

      folio_config = Folio::Config.get_folio_config
      edge_url ||= folio_config['edge_url']
      Rails.logger.debug "- opening new connection to #{edge_url}"
      @conn = Faraday.new(url: edge_url)
      raise "Faraday.new(#{edge_url}) failed!" unless @conn

      @conn.headers['Content-Type'] = 'application/json'
      @conn.headers['Authorization'] = folio_config['edge_authorization']

      @conn
    end



  end

end

