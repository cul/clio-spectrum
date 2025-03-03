class Folio
  module Config
  
    attr_reader :conn, :folio_config

    def self.get_folio_config
      # app_config should have a FOLIO stanza
      folio_config = APP_CONFIG['folio']
      raise "Cannot find 'folio' config in APP_CONFIG!" if folio_config.blank?
      
      # Also check for all the keys we expect to find within that stanza
      # ...

      # Return the entire stanza as a simple hash
      return folio_config
    end

  end

end


