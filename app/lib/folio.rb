class Folio
  

  attr_reader :conn, :folio_config


  def self.get_folio_config
    folio_config = APP_CONFIG['folio']
    raise "Cannot find 'folio' config in APP_CONFIG!" if folio_config.blank?
    # folio_config = HashWithIndifferentAccess.new(folio_config)

    @folio_config = folio_config
  end


  def self.open_edge_connection(url = nil)
    # Re-use an existing connection?
    # How do we detect if this connection object has gone invalid for any reason?
    if @conn
      return @conn if url.nil? || (@conn.url_prefix.to_s == url)
    end

    get_folio_config
    edge_url ||= @folio_config['edge_url']
    Rails.logger.debug "- opening new connection to #{edge_url}"
    @conn = Faraday.new(url: edge_url)
    raise "Faraday.new(#{edge_url}) failed!" unless @conn

    @conn.headers['Content-Type'] = 'application/json'
    @conn.headers['Authorization'] = @folio_config['edge_authorization']

    @conn
  end
  
  def self.get_rtac_xml(instance_ids = nil)
    raise 'Folio.get_rtac() got blank instance_ids' if instance_ids.blank?
    Rails.logger.debug "- Folio.get_itemstatus(#{instance_ids})"
    
  
    # Can be called with either an array or a single instance-id string
    instance_ids = [instance_ids] if instance_ids.is_a?(String)
    
    conn ||= open_edge_connection
    raise "Folio.get_rtac() bad connection [#{conn.inspect}]" unless conn
    
    
    #  ...edge-url.../rtac?instanceIds=00000c2d-2e55-537a-bc18-6da97af23e8f

    instance_ids_param = instance_ids.join(',')
    path = '/rtac?instanceIds=' + instance_ids_param + '&fullPeriodicals=false'

    # Rails.logger.debug "- conn=(#{conn})"
    # Rails.logger.debug "- path=(#{path})"
    response = conn.get path

    if response.status != 200
      # Raise or just log error?
      Rails.logger.error "Folio.get_itemstatus error:  API response status #{response.status}"
      Rails.logger.error 'Folio.get_itemstatus error details: ' + response.body
      return ''
    end

    # NO - naive Hash.from_xml() cannot nest return data consistently
    # response_hash = Hash.from_xml(response.body)
    # response_hash
    
    return response.body
    
  end
  
  # Parse returned data into simple data structure for CLIO display
  # "What gets returned in edge-rtac response"
  # https://folio-org.atlassian.net/wiki/spaces/FOLIJET/pages/1395735
  def self.rtac_to_holdings(rtac_xml = nil)
    return if rtac_xml.nil?
    @holdings = []

    doc = Nokogiri::XML(rtac_xml)
    doc.xpath('//instances/holdings/holding').each do |holding_node|
      # Nokogiri Node -> Rails Hash
      holding = Hash.from_xml(holding_node.to_xml)['holding']

      # Skip suppressed holdings
      next if holding['suppressFromDiscovery'] == 'true'

      # Fill in holdings data that display code expects to find
      holding['location_notes'] = Location.get_app_config_location_notes(holding['location']).to_a
      holding['services'] = self.determine_services(holding).to_a

      # Add this holdings hash to accumulator 
      @holdings.push( holding )
    end

    # Sort Holdings alphabetically by location - to match current CLIO
    @holdings.sort_by! { |holding| holding['location'] }

    return @holdings
  end
  
  
  # COPIED FROM:  Holdings::Record::determine_services()
  # then cleaned up to simplify parameters, remove obscure/obsolete logic, etc.
  def self.determine_services(holding)

    location_code =  holding['locationCode']
    
    services = []

    # ====== SPECIAL COLLECTIONS ======
    # NEXT-1229 - make this the first test
    # special collections request service [only service available for items from these locations]
    # LIBSYS-2505 - Any new locations need to be added in two places - keep them in sync!
    # - the CLIO OPAC: https://github.com/cul/clio-spectrum/blob/master/lib/holdings/record.rb
    # - the Aeon request script:  /www/data/cu/lso/lib/aeondata.pm
    aeon_locations = SERVICE_LOCATIONS['aeon_locations'] || []
    return ['aeon'] if aeon_locations.include?(holding['locationCode'])

    # TODO: What do Orders look like in FOLIO ???
    # # ====== ORDERS ======
    # # Orders such as "Pre-Order", "On-Order", etc.
    # # List of available services per order status hardcoded into yml config file.
    # if orders.present?
    #   orders.each do |order|
    #     # order_config = ORDER_STATUS_CODES[order[:status_code]]
    #     # We no longer have the status as lookup key.
    #     # Do string match againt message found in MARC field to find config.
    #     order_config = ORDER_STATUS_CODES.values.select do |status_config|
    #       status_config['short_message'][0, 5] == order[0, 5]
    #     end.first
    #
    #     raise 'Status code not found in config/order_status_codes.yml' unless order_config
    #     services << order_config['services'] unless order_config['services'].nil?
    #   end
    #   return services.flatten.uniq
    # end

    # ====== ONLINE ======
    # Is this an Online resource?  Do nothing - add no services for online records.
    if holding[:status] == 'online'
      return services.flatten.uniq
    end

    # ====== IN PROCESS ======
    # TODO: What do In-Process holdings look like in FOLIO ???
    if holding['status'] != 'Available' && holding['callNumber'] =~ /in process/i
      services << 'in_process'
    end

    # ====== NO COPY AVAILABLE ======
    # - Something that we have, but which is currently not available (checked-out, etc.)
    if holding['status'] != 'Available'
      services << 'ill_scan'
      services << 'borrow_direct' 
    end

    # ====== COPY AVAILABLE ======
    # - LOTS of different services are possible when we have an available copy,
    #   depending on the item's location, 
    if holding['status'] == 'Available'

      # ------ CAMPUS SCAN ------
      # If campus-scanning is only offered for certain locations....
      campus_scan_locations = SERVICE_LOCATIONS['campus_scan_locations'] || []
      services << 'campus_scan' if campus_scan_locations.include?(holding['locationCode'])
      
      # ------ CAMPUS PAGING / CAMPUS PAGING PILOT ------
      # NEXT-1664 / NEXT-1666 - new Paging/Pickup service for available on-campus material
      campus_paging_locations = SERVICE_LOCATIONS['campus_paging_locations'] || []
      services << 'campus_paging' if campus_paging_locations.include?(holding['locationCode'])

      # ------ FLI PAGING ------
      # LIBSYS-3775 - FLI material is only available to SAC patrons
      fli_paging_locations = SERVICE_LOCATIONS['fli_paging_locations'] || []
      services << 'fli_paging' if fli_paging_locations.include?(holding['locationCode'])

      # ------ BARNARD ALUM PICKUP ------
      # LIBSYS-4084 - add simple link to form for barnard alum access
      barnard_alum_locations = SERVICE_LOCATIONS['barnard_alum_locations'] || []
      services << 'barnard_alum' if barnard_alum_locations.include?(holding['locationCode'])

      # ------ BARNARD-REMOTE ------
      # If this is a Barnard-Remote holding and some items are available,
      # enable the Barnard-Remote request link
      barnard_remote_locations = SERVICE_LOCATIONS['barnard_remote_locations'] || ['none']
      services << 'barnard_remote' if barnard_remote_locations.include?(holding['locationCode'])

      # ------ STARRSTOR ------
      # If this is a StarrStor holding and some items are available,
      # (AND StarrStor is in effect) then enable the StarStor request link. 
      if APP_CONFIG['starrstor_active'].present?
        starrstor_locations = SERVICE_LOCATIONS['starrstor_locations'] || ['none']
        services << 'starrstor' if starrstor_locations.include?(holding['locationCode'])
      end

      # -- RECAP_LOAN --
      recap_loan_locations = SERVICE_LOCATIONS['recap_loan_locations'] || []
      services << 'recap_loan' if recap_loan_locations.include?(holding['locationCode'])

      # -- RECAP_SCAN --  (but not for MICROFORM, CD-ROM, etc.)
      # LIBSYS-4629 - configure ReCAP Scan via location list, like recap_loan
      recap_scan_locations = SERVICE_LOCATIONS['recap_scan_locations'] || []
      if recap_scan_locations.include?(holding['locationCode'])
        unscannable = APP_CONFIG['unscannable_offsite_call_numbers'] || []
        services << 'recap_scan' unless unscannable.any? { |bad| holding['callNumber'].starts_with?(bad) }
      end

      # ------ PRE-CAT ------
      services << 'precat' if holding['location'] =~ /^Precat/
      
    end

    # cleanup the list
    services = services.flatten.uniq

    # Last-chance rules, every physical item should offer some kind of "Scan" and "Pickup"
    # NEXT-1755 - do not offer ILL Scan for Reserves locations
    if holding[:status] != 'online' and not holding['locationCode'].match(/,res/)
      services << 'ill_scan' unless services.include?('campus_scan') or services.include?('recap_scan') or services.include?('ill_scan')
    end


    # TODO:  How do we build this same logic for FOLIO ???
    # only provide borrow direct for printed books, scores, CDs, and DVDs (LIBSYS-1327)
    # https://www.loc.gov/marc/bibliographic/bdleader.html
    # leader 06 - Type of record
    # a = Language material
    # c = Notated music
    # g = Projected medium
    # j = Musical sound recording
    # leader 07 - Bibliographic level
    # m = Monograph/Item
    # unless fmt == 'am' || fmt == 'cm'
    # services.delete('borrow_direct') unless %w(am cm gm jm).include?(fmt)

    # Double-check that we didn't accidently add overlapping services.
    # We can only ever have ONE "Scan" service 
    services.delete('ill_scan') if services.include?('campus_scan')
    services.delete('ill_scan') if services.include?('recap_scan')
    # We can only ever have ONE "Pickup" service 
    services.delete('borrow_direct') if services.include?('campus_paging')
    services.delete('borrow_direct') if services.include?('fli_paging')
    services.delete('borrow_direct') if services.include?('recap_loan')
    

    # return the cleaned up list
    services
  end

 
  
end


