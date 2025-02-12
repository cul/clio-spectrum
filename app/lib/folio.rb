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
  
  # Parse MARC-based Solr holdings into complete holdings data structure for CLIO display
  # with fields:  "id", "location", "locationCode", "callNumber"
  def self.document_to_holdings(document)
    holdings = []
    document.holdings.each do |marc_holding|
      holding = {}
      holding['id']           = marc_holding['0']
      holding['location']     = marc_holding['a']
      holding['locationCode'] = marc_holding['b']
      holding['callNumber']   = marc_holding['h']
      holdings << holding
    end
    return holdings
  end

  def self.get_rtac_xml(instance_ids = nil)
    raise 'Folio.get_rtac() got blank instance_ids' if instance_ids.blank?
    Rails.logger.debug "- Folio.get_rtac_xml(#{instance_ids})"
    
  
    # Can be called with either an array or a single instance-id string
    instance_ids = [instance_ids] if instance_ids.is_a?(String)
    
    conn ||= open_edge_connection
    raise "Folio.get_rtac() bad connection [#{conn.inspect}]" unless conn
    
    #  ...edge-url.../rtac?instanceIds=00000c2d-2e55-537a-bc18-6da97af23e8f
    instance_ids_param = instance_ids.join(',')

    # path = '/rtac?instanceIds=' + instance_ids_param + '&fullPeriodicals=true'
    # path = '/rtac?instanceIds=' + instance_ids_param + '&fullPeriodicals=false'
    # Or let FOLIO return what it thinks we should get back, based on Instance?
    path = '/rtac?instanceIds=' + instance_ids_param

    # Rails.logger.debug "- conn=(#{conn})"
    Rails.logger.debug "- path=(#{path})"
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
    # raise
    return response.body
    
  end
  
  # Parse returned XML data into complete holdings data structure for CLIO display
  # "What gets returned in edge-rtac response"
  #   https://folio-org.atlassian.net/wiki/spaces/FOLIJET/pages/1395735
  def self.rtac_xml_to_holdings(rtac_xml = nil)
    return if rtac_xml.nil?
    rtac_holdings = []
    @errors = []

    doc = Nokogiri::XML(rtac_xml)

    doc.xpath('//instances/errors/error/message').each do |error_message_node|
      @errors.push(error_message_node.content)
    end

    doc.xpath('//instances/holdings/holding').each do |holding_node|
            
      # Nokogiri Node -> Rails Hash
      # Keys in the RTAC response, now keys in the holding hash:
      # ["id", "callNumber", "location", "locationCode", "locationId", "status", "permanentLoanType", "barcode", "suppressFromDiscovery", "totalHoldRequests", "materialType", "library", "holdingsStatements", "holdingsStatementsForIndexes", "holdingsStatementsForSupplements"]
      
      holding = Hash.from_xml(holding_node.to_xml)['holding']

      # Skip suppressed holdings
      next if holding['suppressFromDiscovery'] == 'true'
      
      # Skip Online locations (all data is found in the Instance 856)
      online_location_codes = APP_CONFIG['online_location_codes'] || {}
      next if online_location_codes.include?( holding['locationCode'] )
      
      # reformat nested holdings-statements into simple list
      holding['statements'] = self.build_holdings_statements_list(holding)

      # "status" needs to be a list to support holdings with multiple items
      holding['statuses'] = [ ]
      
      # FOLIO RTAC sometimes returns junk in the 'status' field
      clean_status = self.get_clean_status(holding)
      # Rails.logger.debug("rtac_xml_to_holdings:  clean_status=#{clean_status}")

      # if this holding has a non-empty status...
      if clean_status.present?
        # Each status will have a label and a copy-count (initialized to '1')
        status = { 'label' => clean_status, 'copy_count' => 1 }
        holding['statuses'] << status
      end
      raise
      Rails.logger.debug("rtac_xml_to_holdings:  holding['statuses']=#{holding['statuses']}")
      

      # Fill in additional holdings fields that display code expects to find
      # holding['location_notes'] = Location.get_app_config_location_notes(holding['location']).to_a
      # Why do we support multiple location-notes?
      holding['location_notes'] = [ Location.get_location_note_by_code(holding['locationCode']) ]

      
      # Add this holdings hash to accumulator 
      rtac_holdings.push( holding )
    end

    # raise
    # Sort Holdings alphabetically by location - to match current CLIO
    rtac_holdings.sort_by! { |holding| holding['location'] }
    

    return rtac_holdings, @errors
  end
  
  
  # COPIED FROM:  Holdings::Record::determine_services()
  # then cleaned up to simplify parameters, remove obscure/obsolete logic, etc.
  def self.determine_services(holding)
    return unless holding
    # raise
    
    # Many services are offered only if there is ANY available copy
    available_copy_count = holding['statuses'].count { |status| status['label'] == 'Available' }
    Rails.logger.debug("determine_services:  available_copy_count=#{available_copy_count}")
    # raise
    
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
    if holding['locationCode'] == 'lweb'
      return services.flatten.uniq
    end

    # ====== IN PROCESS ======
    # TODO: What do In-Process holdings look like in FOLIO ???
    if available_copy_count == 0 && holding['callNumber'] =~ /in process/i
      services << 'in_process'
    end

    # ====== NO COPY AVAILABLE ======
    # - Something that we have, but which is currently not available (checked-out, etc.)
    if available_copy_count == 0
      services << 'ill_scan'
      services << 'borrow_direct' 
    end

    # ====== COPY AVAILABLE ======
    # - LOTS of different services are possible when we have an available copy,
    #   depending on the item's location, 
    if available_copy_count > 0

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
    # if holding['status'] != 'online' and not holding['locationCode'].match(/,res/)
    services << 'ill_scan' unless holding['locationCode'].match(/,res/) or
                                  services.include?('campus_scan') or
                                  services.include?('recap_scan') or
                                  services.include?('ill_scan')
                               
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

  # For records with multiple holdings, based on the overall content, adjust as follows:
  # -- remove document delivery options if there is an available offsite copy
  # -- remove borrowdirect and ill options if there is an available non-reserve, circulating copy
  def self.adjust_services_across_holdings(document, holdings)
    return unless document
    return if holdings.empty?

    # set flags
    offsite_copy = 'N'
    available_copy = 'N'

    holdings.each do |holding|
      next unless holding['services']
      offsite_copy = 'Y' if holding['services'].include?('offsite')
      if holding['status'] == 'Available'
        available_copy = 'Y' unless holding['location'] =~ /Reserve|Non\-Circ/ || holding['location'] =~ /Barnard Storage/ || holding['location'] =~ /Barnard Remote/
      end
    end

    # If there's ANY copy available on-campus for scanning,
    # we'll remove any links to ILL Scan services
    campus_scan_available = holdings.any? do |holding|
      next unless holding['services']
      holding['services'].include?('campus_scan')
    end
    holdings.each do |holding|
      next unless holding['services']
      # NEXT-1739 - Campus Scan should NOT block ReCAP Scan any longer
      # record.services.delete('recap_scan') if campus_scan_available
      holding['services'].delete('ill_scan') if campus_scan_available
    end

    # If there's ANY copy available for Pickup, don't offer Borrow Direct
    pickup_available = holdings.any? do |holding|
      next unless holding['services']
      holding['services'].include?('campus_paging') ||
      holding['services'].include?('recap_loan')
    end
    holdings.each do |holding|
      next unless holding['services']
      holding['services'].delete('borrow_direct') if pickup_available
    end

    holdings.each do |holding|
      next unless holding['services']
      # LIBSYS-4423 - For serials, different holdings may offer different issues,
      # don't suppress parallel pickup options
      unless document['format'].any? { |format| format.match?(/journal/i) }
        # NEXT-1559 - don't display Barnard-Remote request link if copy is available
        holding['services'].delete('barnard_remote') if available_copy == 'Y'
      end
    end
    
    return holdings

  end
 
 
   # Some qualities of the bib record affect services offered
  def self.adjust_services_for_bib(document, holdings)
    return unless document
    return if holdings.empty?

    # LIBSYS-1327 - borrow-direct is only valid for certain formats, based on leader
    # 06) Type of record / 07) Bibliographic level
    format_code = document.to_marc.leader[6..7]
    unless %w(am cm gm jm).include?(format_code)
      holdings.each do |holding|
        holding['services'].delete('borrow_direct')
      end
    end    
    
    # NEXT-1673 - only offer "Scan" for certain formats
    scan_formats = APP_CONFIG['scan_formats'] || ['book']
    # If there's no intersection between this bib's formats and the scannable list,
    # Then remove all scan-related service links
    if (document['format'] & scan_formats).empty?
      holdings.each do |holding|
        holding['services'].delete('ill_scan')
        holding['services'].delete('recap_scan')
      end
    end

  end
  
  # Folio.adjust_holdings_status_for_offsite(holdings, scsb_status)
  def self.adjust_holdings_status_for_offsite(holdings, scsb_status)
    # SCSB Status is a map of barcode to "Available"/"Unavailable"
    # {
    #   "CU18799175"  =>  "Available", ...
    # }
    holdings.each do |holding|
      next unless holding['barcode']
      if scsb_status.has_key?( holding['barcode'] )
        holding['status'] = scsb_status[holding['barcode'] ]
      end
    end
    # raise
  end


  def self.get_clean_status(holding)
    
    # FOLIO RTAC assigns 'Multi' when holding status cannot be determined (?)
    # How do we want this represented in our holdings hash?
    # return 'unknown' if holding['status'] == 'Multi'
    return '' if holding['status'] == 'Multi'
    
    # FOLIO RTAC may assign the first Holdings-Statement-Note as the status?
    # (maybe when there are no item-records?)
    # Try to detect this.
    # And if we find it, what?  Is it available or unavailable???
    if holding.has_key?('statements')
      holding['statements'].each do |statement|
        # return 'unknown' if holding['status'] == statement
        return '' if holding['status'] == statement
      end
    end

    # If we didn't find any of the above problems, then the current value is good
    return holding['status']
  end
 
 
 
  # FOLIO RTAC Holdings Statements are structured like so:
  #     <holdingsStatements>
  #         <holdingsStatements>
  #             <statement>1935-1939, 1955</statement>
  #             <note></note>
  #             <staffNote></staffNote>
  #         </holdingsStatements>
  #         <holdingsStatements>
  #             <statement>LIBRARY LACKS: 1935:A-Bep(5 fiches)</statement>
  #             <note></note>
  #             <staffNote></staffNote>
  #         </holdingsStatements>
  #     </holdingsStatements>
  #     <holdingsStatementsForIndexes/>
  #     <holdingsStatementsForSupplements/>
  # And this will be turned into an even more complex nested hash/array ruby structure
  #
  # Reformat into a simple array of text strings for display in the view 
  def self.build_holdings_statements_list(holding)    
    statements = []
    return statements unless holding
    
    for field in ['holdingsStatements', 'holdingsStatementsForIndexes', 'holdingsStatementsForSupplements'] do
      next unless holding[field] && holding[field][field]
      
      # If single-hash, convert to array. If array, leave as array.
      holdings_fields = holding[field][field]
      holdings_fields = holdings_fields.is_a?(Array) ? holdings_fields : [holdings_fields] 
      
      for field_iteration in holdings_fields do
        for subfield in ['statement', 'note', 'staffNote'] do
          next unless field_iteration[subfield]
          statements.push field_iteration[subfield]
        end
      end

    end
    return statements
  end
 
  # RTAC will return one Holding per Item.
  # We want to consolidate into one Holding per Location/Call-Number
  # Other fields (status, holdings statements, etc.) become lists
  def self.consolidate_holdings(input_holdings_list)
    return [] unless input_holdings_list.present?

    # Sort Holdings alphabetically by location/call-number
    # input_holdings_list.sort_by! { |holding| holding['location'] + holding['callNumber'] }
    input_holdings_list.sort_by! { |holding| holding['location'] + holding['callNumber'] }

    # Every holding should have certain default fields, even if they're empty.
    # Assert that they are present for every holding.
    self.assert_default_fields(input_holdings_list)

    # Peel off first input holding as the first of the output holdings.
    # We will compare subsequent input-holdings against this, to
    # see if they're new locations, or need to be consolidated.
    output_holding = input_holdings_list.shift

    # Initialize our output-holdings-list with this first holding
    output_holdings_list = [ output_holding ]
# raise   
    # Consider remaining input Holdings...
    input_holdings_list.each do |input_holding|
      Rails.logger.debug("considering new input holding #{input_holding['location']}...")
      
      # Is the next holding for a DIFFERENT Location/Call-Number?
      if (output_holding['locationCode'] != input_holding['locationCode']) || 
         (output_holding['callNumber']   != input_holding['callNumber'])
        # If so, we're done with our current "output-holding", and this 
        # new holding becomes the one to compare against...
        output_holding = input_holding
        # And also we want to add this new holding into our output list
        output_holdings_list << input_holding
        Rails.logger.debug("adding input holding #{input_holding['location']} to output-holdings-list")
        next
      end
      
      # If we've dropped to here then the new input-holding we're considering
      # is another item in for the same location as our current output-holding.
      # We need to merge the data.
      self.merge_holdings_data(output_holding, input_holding)
    end

    # We've looped over all input holdings, merging same-location data.
    # Return the resulting consolidated list.
    return output_holdings_list
  end
  
  def self.assert_default_fields(holdings_list)
    holdings_list.each do |holding|
      holding['statements'] = [] unless holding['statements'].present?
      holding['statuses'] = []   unless holding['statuses'].present?
    end
  end
      
  # Merge the data from "input" INTO the "output" data structure
  def self.merge_holdings_data(output_holding, input_holding)

    # Does the Input holding have any statements that are not already in the output holding?
    # If we find something new, add it.
    input_holding['statements'].each do |statement|
      if output_holding['statements'].include?(statement)
        output_holding['statements'] << statement
      end
    end

    # Loop over all statuses of the new input holding.
    # If it's a redundant status, just increment the copy-count.
    # If it's a new status, add it to the status-list.
    input_holding['statuses'].each do |input_status|
      Rails.logger.debug("merge_holdings_data:  input_status=#{input_status}")
      found = false
      output_holding['statuses'].each do |output_status|
        Rails.logger.debug("merge_holdings_data:  output_status=#{output_status}")
        # Yes, we found a matching status!
        if output_status['label'] == input_status['label']
          output_status['copy_count'] += input_status['copy_count']
          found = true
        end
      end
      
      # No match found - this is a NEW status for this holding
      if found == false
        output_holding['statuses'] << input_status
      end
    end

    # Done.  The output-holding was modified in-place.
  end
     
  
end


