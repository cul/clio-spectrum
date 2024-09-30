# encoding: utf-8
module HoldingsHelper

  SHORTER_LOCATIONS = {
    'Temporarily unavailable. Try Borrow Direct or ILL' =>
        'Temporarily Unavailable',
    'Butler Stacks (Enter at the Butler Circulation Desk)' =>
        'Butler Stacks',
    'Offsite - Place Request for delivery within 2 business days' =>
        'Offsite',
    'Offsite (Non-Circ) Request for delivery in 2 business days' =>
        'Offsite (Non-Circ)'
  }.freeze

  def shorten_location(location)
    SHORTER_LOCATIONS[location.strip] || location
  end

  def process_holdings_location(loc_display)
    location, call_number = loc_display.split(' >> ')
    output = ''.html_safe
    output << shorten_location(location) # append will html-escape content
    # if call_number
    #   # NEXT-437 - remove the separator between location and call number
    #   # output << " >> "
    #   output << content_tag(:span, " #{call_number} ", class: 'call_number').html_safe
    # end
    # simplify:
    output << "  #{call_number}" if call_number
    output
  end

  # Support for:
  #   NEXT-113 - Do not make api request for online-only resources
  #   NEXT-961 - Incorporate Law records into CLIO
  def has_loadable_holdings?(document)
    # 'location' alone is only found in the 'location_facet' field, which is currently
    # indexed but not stored, so I can't use it.

    # Use the full 992b (location_call_number_id_display) and break it down redundantly here.
    # examples:
    #   Online >> EBOOKS|DELIM|13595275
    #   Lehman >> MICFICHE Y 3.T 25:2 J 13/2|DELIM|10465654
    #   Music Sound Recordings >> CD4384|DELIM|2653524
    # Or, for Law:
    #   Law >> JK1061 .B66 1992
    return false unless location_call_number_id = document[:location_call_number_id_display]

    Array.wrap(location_call_number_id).each do |portmanteau|
      location = portmanteau.partition(' >>').first
      # This list of "Locations" are not available for live holdings lookups
      return false if ['Law'].include? location
      # If we find any location that's not Online, Yes, it's a physical holding
      return true if location && location != 'Online'
    end

    # If we dropped down without finding a physical holding, No, we have none
    false
  end

  def online_link_hash(document)
    links = []
    # If we were passed, e.g., a Summon document object
    return links unless document.is_a?(SolrDocument)

    # ONLINE HOLDINGS - only for Columbia, suppress for ReCAP partner records
    return links unless document.columbia?

    document['url_munged_display'].listify.each do |url_munge|
      # See parsable_856s.bsh for the serialization code, which we here undo
      delim = '|||'
      url_parts = url_munge.split(delim).map(&:strip)
      ind2 = url_parts[0]
      subfield3 = url_parts[1]
      subfieldU = url_parts[2]
      subfieldZ = url_parts[3]

      # return empty links[] if the $u isn't a URL (bad input data)
      url_regex = Regexp.new('(?i)\b((?:[a-z][\w-]+:(?:/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:\'".,<>?«»“”‘’]))')

      # No, don't stop on first non-URL,
      # just skip it and move on to the next munged 856.
      # return links unless subfieldU =~ url_regex
      next unless subfieldU =~ url_regex

      title = "#{subfield3} #{subfieldZ}".strip
      title = subfieldU if title.empty?
      note  = case ind2
              when '1'
                ' (version of resource)'
              when '2'
                ' (related resource)'
              when '3'    
                ''
              when '4'
                ' (related resource)'
              else '' # omit note for ind2 == 0, the actual resource
      end
      url = subfieldU
      
      # NEXT-1852 - new resolver links in CLIO test
      if (APP_CONFIG['resolver_rewrite_856'] || false)
        url = rewrite_resolver_url(url)
        # NEXT-1854 - If URL is used as link text, it should be rewritten
        title = rewrite_resolver_url(title)
      end

      # links << [title, note, url]   # as ARRAY
      links << { title: title, note: note, url: url } # as HASH
    end

    # remove google links if more than one exists

    if links.select { |link| link[:title].to_s.strip == 'Google' }.length > 1
      links.reject! { |link| link[:title].to_s.strip == 'Google' }
    end
    
    # Nope, this doesn't belong here.  776 isn't an "online" link.
    # # LIBSYS-2405 - create link to "original analog" from 776$w
    # if document.has_key?(:marc_display) and Rails.env != 'clio_prod'
    #   document.to_marc.each_by_tag('776') do |t776|
    #     next unless t776.indicator1 == '0'
    #     next unless t776['i'] and t776['w']
    #     # Sequence - MFHD ID used to gather all associated fields
    #     record_control_number = t776['w']
    #     next unless record_control_number.starts_with? '(NNC)'
    #     record_control_number.gsub!(/\D/, '')
    #     next unless record_control_number.length > 0
    #     # url = "https://clio.columbia.edu/catalog/#{record_control_number}"
    #     links << { title: t776['i'], url: solr_document_path(record_control_number) }
    #   end
    # end

    links
    #    links.sort { |x,y| x.first <=> y.first }
  end

  # NEXT-1852 - new resolver links in CLIO test
  def rewrite_resolver_url(url)
    # Only rewrite URLs to the legacy HTTP resolver CGI
    old_url = 'http://www.columbia.edu/cgi-bin/cul/resolve?'
    return url unless url.start_with?(old_url)

    # Only rewrite if we have a new resolver URL configured
    return url unless new_url = APP_CONFIG['resolver_base_url']
    
    # Isolate the resolver key from the full URL
    key = url.delete_prefix(old_url)

    # Rewritten URL is the new base url and the key, no delimiter
    return new_url + key
  end



  SERVICE_ORDER = %w(campus_scan recap_scan offsite ill_scan ill campus_paging fli_paging recap_loan barnard_remote starrstor barnard_alum avery_onsite aeon microform precat on_order borrow_direct recall_hold in_process doc_delivery ).freeze

  # parameters: title, link (url or javascript), optional extra param
  # When 2nd param is a JS function,
  # that function will be called with two args: current bib-id and extra param
  # SERVICES = {
  def serviceConfig
    # just return a hash, the same as the constant did, but
    # now we can call methods as we build the config.
    {
      # ====  SCAN SERVICES  ====
      'campus_scan'    => {link_label: 'Scan',          service_url: campus_scan_link, 
                           tooltip:    'Campus Scan',   js_function: 'OpenWindow'},
      'recap_scan'     => {link_label: 'Scan',          service_url: recap_scan_link, 
                           tooltip:    'ReCAP Scan',    js_function: 'OpenWindow'},
      'offsite'        => {link_label: 'Scan',          service_url: offsite_link, 
                           tooltip:    'Offsite',       js_function: 'OpenWindow'},
      # NEXT-1819 - replace ill_link with ill_scan_link
      # 'ill'            => {link_label: 'Scan',          service_url: ill_link,
      #                      tooltip:    'Illiad Book/Article Scan'},
      'ill_scan'       => {link_label: 'Scan',          service_url: ill_scan_link,
                           tooltip:    'Illiad Book/Article Scan'},
      # ====  PICK-UP SERVICES  ====
      'campus_paging'  => {link_label: 'Pick-Up',       service_url: campus_paging_link, 
                           tooltip:    'Campus Paging', js_function: 'OpenWindow'},
      'fli_paging'     => {link_label: 'FLI Pick-Up',   service_url: fli_paging_link, 
                           tooltip:    'FLI Paging',    js_function: 'OpenWindow'},
      'recap_loan'     => {link_label: 'Pick-Up',       service_url: recap_loan_link, 
                           tooltip:    'ReCAP Loan',    js_function: 'OpenWindow'},
      'borrow_direct'  => {link_label: 'Pick-Up (Borrow Direct)', service_url: borrow_direct_link,
                           tooltip:    'Borrow Direct' },
      # ====  OTHER SERVICES  ====
      'barnard_remote' => {link_label: 'Pick-Up (at Barnard Library)', service_url: barnard_remote_link, 
                           tooltip:    'Barnard Remote',   js_function: 'OpenWindow'},
      'starrstor'      => {link_label: 'Pick-Up (Temporary Storage)', service_url: starrstor_link, 
                           tooltip:    'East Asian Remote Storage',   js_function: 'OpenWindow'},
      'barnard_alum'   => {link_label: 'Barnard Alum Pick-Up', 
                           service_url: 'https://library.columbia.edu/resolve/barlib0001#'},
      'avery_onsite'   => {link_label: 'On-Site Use',      service_url: avery_onsite_link, 
                           tooltip:    'Avery Onsite',     js_function: 'OpenWindow'},
      # 'aeon'           => {link_label: 'Special Collections', service_url: 'http://www.columbia.edu/cgi-bin/cul/aeon/request.pl?bibkey='},
      'aeon'           => {link_label: 'Special Collections', service_url: aeon_link},
      'microform'      => {link_label: 'Arrange for Access', 
                           service_url: 'https://library.columbia.edu/libraries/pmrr/services.html?'},
      'precat'         => {link_label: 'Precataloging', service_url: precat_link, 
                           js_function: 'OpenWindow'},
      'recall_hold'    => {link_label: 'Recall / Hold', service_url: recall_hold_link},
      'on_order'       => {link_label: 'On Order',      service_url: on_order_link,
                           js_function: 'OpenWindow'},
      'in_process'     => {link_label: 'In Process',    service_url: in_process_link,
                           js_function: 'OpenWindow'},
      # 'doc_delivery'   => {link_label: 'Scan', 'https://www1.columbia.edu/sec-cgi-bin/cul/forms/docdel?'}
    }
  end

  def service_links(services, clio_id, holding_id = nil)
    return [] unless services && clio_id

    # For some reason, this singleton value is stored in an array.  :(
    holding_id = holding_id.first if holding_id.is_a?(Array)
    
    # ACTUALLY, we "condense" similar holdings into "entries".
    #   An "entry" is a group of holdings sharing: location/call-num
    #
    # When holding_id is non-singleton, that means the service link
    # is offered with respect to the LIST of similar holdings.
    # This is OK for bib-based services (campus paging/scanning, or BD),
    # but NOT OK for holdings-based services (recap-loan / recap-scan).
    #
    # fixes?
    # 1) don't condense holdings with recap-loan/recap-scan.  
    #    this would result in many more "Requests:" sections.
    # 2) Pickup/Scan link opens CLIO-side intermediary holdings-selection form, then jumps by bib/mfhd_id to Valet
    #    But - GUI issues, not easy to do
    # 3) Pickup/Scan link jumps by-bib go Valet, then opens Valet-side intermediary holdings-selection form
    #    GUI is already figured out, easy to do
    #    But - do we have to worry that different holdings would have different availabilities?
    #       due to new offsite-availability rules?
    #       what are those rules that determine CLIO's offering of the recap services?
    #
    # recap_loan_locations - list of locations.  All holdings within an "entry" will have same location
    # scan_formats - this turns off recap_scan, but format is a bib-level element, all holdings will have the same format
    # unscannable_offsite_call_numbers - call-number is also the same across an "entry"
    #
    #    OK, so it seems safe to let Valet treat an entire "entry" the same?
    #    But -- CLIO service links are by-entry, not by-bib.  So still possibly a problem,
    #    if a ReCAP bib has two entries/holdings, might they have different locations or call-numbers?  
    #      Such that one holding is valid and the other is not?  How likely?  
    #      Some micro, some not?  or split locations?  Within the same bib?  Very very unlikely, right?
    #
    # so we're coming around to re-inserting the holdings-selection form in Valet.
    # if we do that, how?
    # - different routes, different arg patterns to the recap_blah paths?
    #     with a "loopback" holding-selction GET form?
    # raise 

    # # LIBSYS-2891 / LIBSYS-2892 - libraries closed, suspend ALL services
    # 6/2020 - Suspended services are beginning to be reinstated.
    # Which services are reinstated?
    reinstated = APP_CONFIG['reinstated_services'] || []
    # Which of this bib's services have now been reinstated? 
    services.select! { |service| reinstated.include?(service) }

    # # NEXT-1660 - COVID - Don't offer offsite requests for Hathi ETAS
    # etas_status = Covid.lookup_db_etas_status(clio_id)
    # services.delete('offsite') if (APP_CONFIG['hathi_etas'] && etas_status == 'deny')

    # If none, give up.  Immediately return empty service list.
    return [] unless services
    # If some, proceed as we did pre-COVID.

    service_links = services.select { |svc| SERVICE_ORDER.index(svc) }.sort_by { |svc| SERVICE_ORDER.index(svc) }.map do |svc|
      # title, link, extra = serviceConfig[svc]

      service_config = serviceConfig[svc]
      link_label  = service_config[:link_label]
      service_url = service_config[:service_url]
      js_function = service_config[:js_function]
      tooltip     = service_config[:tooltip]
      
      link_target = service_url + clio_id.to_s
      
      # NEXT-1693 - nope, don't do this anymore
      # # Some links need more than bib.  ReCAP needs holdings id too.  For example:
      # #     https://valet.cul.columbia.edu/recap_loan/2929292/10086
      # #     https://valet.cul.columbia.edu/recap_scan/2929292/10086
      # link_target += '/' + holding_id.to_s if ['recap_loan', 'recap_scan'].include?(svc)

      link_options = {}
      
      # If we're supposed to wrap the link in a JS function...
      if js_function
        onclick_js = "#{js_function}('#{link_target}'); return false;"
        link_options['onclick'] = onclick_js.html_safe
        link_target = '#'
      end
      
      # If we've got a tooltip to display...
      # (feature only currently enabled for CUD)
      if tooltip
        show_tooltips = false
        show_tooltips = true if current_user && current_user.has_role?('site', 'pilot')
        show_tooltips = true if APP_CONFIG['admin_ips'] && APP_CONFIG['admin_ips'].include?(request.remote_ip)
        if show_tooltips
          link_options['data-toggle'] = 'tooltip'
          link_options['data-placement'] = 'right'
          link_options['title'] = tooltip
        end
      end

      link_to link_label, link_target, link_options
      
      # link = js_function.present? ? '#' : service_url
      # onclick = js_function.present? ? "#{js_function}('#{bibid})" : ''
      # onclick = onclick.
      #
      # if js_function
      # link_to link_label,
      #
      # # URL services
      # if link =~ /^http/
      #   link += bibid
      #   link_to title, link, target: '_blank'
      # else
      #   # JavaScript services (open url in pop-up window)
      #   # Some functions (e.g., Valet) accept additional arg to pass along to the JS function
      #   js_function = extra.present? ? "#{link}('#{bibid}', '#{extra}')" : "#{link}('#{bibid}')"
      #   onclick_js = "#{js_function}; return false;"
      #   link_to title, '#', onclick: onclick_js.html_safe
      # end
    end
    
    service_links = service_links.compact

    return service_links.compact
  end

  def process_online_title(title)
    title.to_s.gsub(/^Full text available from /, '').gsub(/(\d{1,2})\/\d{1,2}(\/\d{4})/, '\1\2')
  end

  # Create a holdings "Entry", mirroring the JSON returned from a backend holdings lookup,
  # but with passed-in data
  def create_dummy_entry(options = {})
    entry = {
      'location_name' => options[:location_name] ||= 'Location',
      'copies'        => []
    }

    entry['call_number'] = options[:call_number] if options[:call_number]

    entry
  end

  def add_display_elements(entries)
    entries.each do |entry|
      # location links, hours
      location = Location.match_location_text(entry['location_name'])

      entry['location_link'] = format_location_link(entry['location_name'])

      # if location && location.library && (hours = location.library.hours.find_by_date(Date.today))
      if location && location.library_code && (hours = LibraryHours.where(library_code: location.library_code).where(date: Date.today))
        entry['hours'] = hours.first.to_opens_closes unless hours.empty?
      end

      # location notes
      # "additional" are from app_config, or hard-coded application logic (e.g., pegasus)
      more_notes = additional_holdings_location_notes(nil, entry['location_name'])
      # There might already be location notes - if so, append.
      entry['location_note'] = if entry['location_note']
                                 Array.wrap(entry['location_note'].html_safe)
                               else
                                 []
                               end
      entry['location_note'].concat(more_notes) if more_notes && !more_notes.empty?

      # add status icons
      entry['copies'].each do |copy|
        copy['items'].each_pair do |_message, details|
          # # NEXT-1745 - turn them back on
          # # # NEXT-1668 - turn off colored indicators
          # # ### status_image = 'icons/' + 'none' + '.png'
          # status_image = 'icons/' + details['status'] + '.png'
          # status_label = details['status'].humanize
          # # details['image_link'] = image_tag('icons/' + details['status'] + '.png')
          # details['image_link'] = image_tag(status_image, title: status_label, alt: status_label)
          details['image_link'] = status_image_tag(details['status'])
        end
      end
    end

    sort_item_statuses(entries)

    entries
  end

  
  def status_image_tag(status)
    status.gsub!(' ', '_')
    status_label = status.humanize
    status_image = 'icons/' + status.downcase + '.png'
    
    # TODO:  FOLIO gives unexpected item statuses.  Use "?" until we figure out something better
    FileTest.exist?("#{Rails.root}/app/assets/images/#{status_image}") or status_image = 'icons/non_circulating.png'
    
    image_tag(status_image, title: status_label, alt: status_label)
  end


  ITEM_STATUS_RANKING = %w(available some_available not_available none online).freeze

  def sort_item_statuses(entries)
    entries.each do |entry|
      entry['copies'].each do |copy|
        items = copy['items']
        copy['items'] = items.sort_by { |_k, v| ITEM_STATUS_RANKING.index(v['status']) }
      end
    end

    # NOTE: This sort_by step changes the copy[:items] structure from:
    #       {message => {:status => , :count => , etc.}, ...}
    #     to:
    #       [[message, {:status => , :count => , etc.}], ...]
    # in order to preserve the sort order.
  end

  # Extract bibkeys for a particular type of key
  # (e.g., 'isbn', 'issn', 'oclc', 'lccn')
  def extract_by_key(document, key)
    display_values = document[key + '_display']
    return unless display_values

    bibkeys = Array.wrap(display_values).map do |value|
      # always remove all white-space from any key
      value.gsub!(/\s/, '')
      # LCCN sometimes has a strange suffix.  Remove it.
      # e.g., "84162131 /HE" or "78309771 //r83"
      value.gsub!(/\/.+$/, '') if key == 'lccn'
      # For OCLC numbers, strip away the prefix ('ocm' or 'ocn')
      value.gsub!(/^oc[mn]/, '') if key == 'oclc'
      # Here's what we want returned - key:value, e.g.
      "#{key}:#{value}"
    end

    # NEXT-1690 - old East Asian records store OCLC in 079$a
    # If we find it there, replace value from the 035 OCLC field
    # https://www1.columbia.edu/sec/cu/libraries/inside/clio/docs/bcd/cpm/cpmrec/cpm108.html
    if key == 'oclc'
      if document.key?('marc_display') && document.to_marc['079']
        value = document.to_marc['079']['a'] || ''
        value.gsub!(/^oc[mn]/, '')
        bibkeys = [ "#{key}:#{value}" ] if value
      end
    end

    return bibkeys.uniq
  end

  def extract_standard_bibkeys(document)
    bibkeys = []

    # NEXT-1633, NEXT-1635 - COVID - Hathi match by OCLC preferred
    bibkeys << extract_by_key(document, 'oclc')
    bibkeys << extract_by_key(document, 'isbn')
    bibkeys << extract_by_key(document, 'issn')
    bibkeys << extract_by_key(document, 'lccn')

    # Some Hathi records were directly loaded into Voyager.
    # These have direct Hathi links in their 856 - and these
    # links have a standard ID number not otherwise available.
    online_link_hash(document).each do |link|
      next unless link[:url].start_with? 'http://catalog.hathitrust.org'
      next unless link[:url] =~ /api\/volumes\/\w+\/\d+.html/

      id_type, id_value = link[:url].match(/api\/volumes\/(\w+)\/(\d+).html/).captures

      # put at the front - so later first-found processing hits this one
      bibkeys.unshift(id_type + ':' + id_value)
    end

    # Sometimes the document data from Solr has invalid chars in the bib keys.
    # Strip these out so they don't trip up any code which uses these bibkeys.
    bibkeys.flatten.compact.map do |bibkey|
      bibkey.gsub(/[^a-zA-Z0-9\:\-]/, '').strip
    end.uniq
  end

  # When bib records have a URL in their 856, they will have a holdings
  # record with location Online but with NO URL DETAILS.
  # These need to be detected, so that we can skip these holdings entries.
  def holdings_online_without_url?(json_entry)
    # Not an online holding if this are missing
    return false if json_entry['location_name'] != 'Online'

    # Shouldn't happen
    return false unless json_entry['copies']

    found_url = false
    json_entry['copies'].each do |copy|
      found_url = true if copy['urls']
    end

    # If we found a URL block, this entry HAS a url
    return false if found_url

    # Only if we dropped down to here are we on an entry
    # which is marked Online but is missing URL details.
    true
  end

  def get_hathi_holdings_data(document)
    return nil unless document

    hathi_holdings_data = nil

    # format will be type:value, type:value,
    # e.g., lccn:2006921508, oclc:70850767
    bibkeys = extract_standard_bibkeys(document)
    bibkeys.each do |bibkey|
      id_type, id_value = bibkey.split(':')
      next unless id_type && id_value
      
      ### LIBSYS-3996 - End ETAS
      # # NEXT-1633, NEXT-1635 - COVID
      # # If this record is in our holdings-overlap report
      # # (as Limited-View but ETAS-accessible OR as full-view)
      # # then we ONLY want to do lookups by OCLC number
      # if (document['hathi_access_s'].present?)
      #   next unless id_type == 'oclc'
      # end

      hathi_holdings_data = fetch_hathi_brief(id_type, id_value)
      break unless hathi_holdings_data.nil?
    end
    
    # nothing found, no further processing
    return nil if hathi_holdings_data.blank?

    # NEXT-1633, NEXT-1635 - COVID - We've fetched Hathi bib availability data.
    # Now - check the Hathi "holdings overlap" status from the Solr record.
    # - "allow" means Full-View
    # - "deny" means Limited View, but temporary ETAS access
    
    ### LIBSYS-3996 - End ETAS
    # # If either Hathi Access code is FOUND, return full hathi holdings data
    # if (document['hathi_access_s'].present?)
    #   return hathi_holdings_data
    # end

    ### LIBSYS-3996 - End ETAS
    # # If NO HATHI ACCESS FOUND...
    # # - "Full view" means we have access, allow it
    # # - "Limited" or Blank means we don't have full-access - suppress it
    # # - blank means NO holdings overlap: pass-thru "Full View", suppress "Limited"
    # if (document['hathi_access_s'].blank?)
    #   # Look at the Rights of each Item in the Hathi API response,
    #   # If the item has limited-view, we'll suppress it from patron display,
    #   #   because search-only access to a Hathi pageturner is useless.
    #   # (Otherwise, the item has full-view and we'll leave it in for patrons)
    #   hathi_holdings_data['items'].delete_if do |item|
    #     item['usRightsString'].downcase.include?('limited')
    #   end
    # end

    # Look at the Rights of each Item in the Hathi API response,
    # If the item has limited-view, we'll suppress it from patron display,
    #   because search-only access to a Hathi pageturner is useless.
    # (Otherwise, the item has full-view and we'll leave it in for patrons)
    hathi_holdings_data['items'].delete_if do |item|
      item['usRightsString'].downcase.include?('limited')
    end
    
    # Did we strip away the last item?
    # If so, there's no Hathi availability.
    return nil unless hathi_holdings_data['items'].present?

    hathi_holdings_data
  end


  # def lookup_etas_status_NO_LONGER_CALLED(document)
  #   begin
  #     # Lookup by bib id (this will work for Voyager items)
  #     id = document.id
  #     # sql = "select * from hathi_etas where local_id = '#{id}'"
  #     sql = "select * from hathi_overlap where local_id = '#{id}'"
  # THIS IS SQLITE ONLY:
  #     BROKEN:   records = ActiveRecord::Base.connection.execute(sql)
  #     return records if records.size > 0
  #   
  #     # Lookup by OCLC number (this will work for Law, ReCAP)
  #     oclc_keys = extract_by_key(document, 'oclc')
  #     oclc_keys.each do |oclc_key|
  #       oclc_tag, oclc_value = oclc_key.split(':')
  #       next unless oclc_tag.eql?('oclc') && oclc_value
  #       # sql = "select * from hathi_etas where oclc = '#{oclc_value}'"
  #       sql = "select * from hathi_overlap where oclc = '#{oclc_value}'"
  #       records = ActiveRecord::Base.connection.execute(sql)
  #       return records if records.size > 0
  #     end
  #   rescue
  #     # If anything went wrong, just return failure
  #     return nil
  #   end
  #   
  #   return nil
  # end
  
  # hathi urls look like:
  #   http://catalog.hathitrust.org/api/volumes/brief/oclc/2912401.json
  def fetch_hathi_brief(id_type, id_value)
    return nil unless id_type && id_value

    hathi_brief_url = 'https://catalog.hathitrust.org/api/volumes' \
                      "/brief/#{id_type}/#{id_value}.json"
    # Rails.logger.debug "hathi_brief_url=#{hathi_brief_url}"
    http_client = HTTPClient.new
    http_client.ssl_config.set_default_paths
    http_client.connect_timeout = 10 # default 60
    http_client.send_timeout    = 10 # default 120
    http_client.receive_timeout = 10 # default 60

    # Rails.logger.debug "fetch_hathi_brief() get_content(#{hathi_brief_url})"
    begin
      hathi_lookup_start = Time.now
      json_data = http_client.get_content(hathi_brief_url)
      hathi_lookup_elapsed_ms = (Time.now - hathi_lookup_start) * 1000
      Rails.logger.debug "Hathi lookup #{hathi_brief_url} - #{hathi_lookup_elapsed_ms}ms"

      hathi_holdings_data = JSON.parse(json_data)

      # Hathi will pass back a valid, but empty, response.
      #     {"records"=>{}, "items"=>[]}
      # This means no hit with this bibkey, so return nil.
      return nil unless hathi_holdings_data &&
                        hathi_holdings_data['records'] &&
                        !hathi_holdings_data['records'].empty?

      ### NEXT-1633 - COVID - stop suppressing Limited View Hathi links
      ### LIBSYS-3996 - End ETAS, restore previous behavior (suppress "limited")
      # NEXT-1357 - Only display 'Full view' HathiTrust records
      hathi_holdings_data['items'].delete_if do |item|
        item['usRightsString'].downcase.include?('limited')
      end

      # Only display Hathi 'Full view' holdings.
      # If there are none, supress any Hathi data.
      return nil unless hathi_holdings_data &&
                        hathi_holdings_data['items'] &&
                        !hathi_holdings_data['items'].empty?

      return hathi_holdings_data
    rescue => error
      Rails.logger.error "Error fetching #{hathi_brief_url}: #{error.message}"
      return nil
    end
  end

  # polymorphic:
  # - build label based on passed string ('access' value in overlap report)
  # - build label based on item rights (field 'usRightsString' of passed hash)
  def hathi_link_label(access_or_item)
    test_value = access_or_item if access_or_item.is_a?(String)
    test_value = access_or_item['usRightsString'] if access_or_item.is_a?(Hash)
    test_value ||= ''
    
    # Forms of full-view language
    return 'Full view' if test_value.match(/full/i)
    return 'Full view' if test_value.match(/allow/i)

    # While ETAS is active, override limited-view/deny
    if APP_CONFIG['hathi_etas']
      return 'Log in for temporary access' if test_value.match(/deny/i)
      return 'Log in for temporary access' if test_value.match(/limited/i)
    end

    # normal language for limited-view items
    return 'Limited (search-only)'  if test_value.match(/deny/i)
    return 'Limited (search-only)'  if test_value.match(/limited/i)

    # default case - return the language as given
    return test_value
  end
  # def hathi_item_link_label(item)
  #   if (item['usRightsString'].downcase.include?('full'))
  #     return item['usRightsString']
  #   elsif (item['usRightsString'].downcase.include?('limited'))
  #     return 'Log in for temporary access'
  #   else
  #     return item['usRightsString']
  #   end
  # end

  # # Return the
  # def format_hathi_search_result_link(document)
  #   # show-links feature must be toggled on
  #   return nil unless APP_CONFIG['hathi_search_results_links']
  #   # document must have a hathi access value
  #   return nil unless document['hathi_access_s']
  #
  #   # NEXT-1668 - turn off colored indicators
  #   # green_check = image_tag('icons/online.png', class: 'availability')
  #   green_check = image_tag('icons/none.png', class: 'availability')
  #   label = hathi_link_label(document['hathi_access_s'])
  #
  #   # mark with spans so that onload JS can manipulate link DOM
  #   # (add bib_#{document.id} as shortcut for JavaScript)
  #   bib_class = "bib_#{document.id}"
  #   label_span = content_tag(:span, label, class: "hathi_label #{bib_class}")
  #   link_span = content_tag(:span, label_span, class: "hathi_link #{bib_class}")
  #
  #   return green_check + link_span
  #
  #   # TODO - real-time defered JS lookup of URL, for live linking
  #   # = image_tag("icons/online.png")
  #   #
  #   # -# %a{href: "#{item['itemURL']}"}= item['usRightsString']
  #   # %a{href: hathi_item_url(item)}= hathi_link_label(item)
  # end
  
  def hathi_item_url(item)
    # if the 'item' we get isn't parsable for any reason,
    # we'll just return nil
    begin
      # For Full view items, just return the direct itemURL
      if (item['usRightsString'].downcase.include?('full'))
        return item['itemURL']
      end
      # For any other rights ("Limited", or any unexpected value),
      # use Automatic Login: https://www.hathitrust.org/automatic_login
      id = item['htid']
      entity_id = 'urn:mace:incommon:columbia.edu'
      link = "http://hdl.handle.net/2027/#{id}?urlappend=%3Bsignon=swle:#{entity_id}"
      return link
      
      # reverse-engineered Shib auto-login work below, 
      # superceded by automatic login
      # # we'll construct a shib sso shortcut URL.
      # shibURL  = 'https://babel.hathitrust.org/Shibboleth.sso/Login?' +
      #            'entityID=urn:mace:incommon:columbia.edu&target='
      # 
      # babelURL = 'https://babel.hathitrust.org/cgi/pt?id='
      # # automatically checkout - do we want this?
      # # no, we don't, it blocks other patrons for using the book.
      # checkoutParam = ';a=checkout'
      # encodedURL = CGI.escape( babelURL + item['htid'] + checkoutParam)
      # encodedURL = CGI.escape( babelURL + item['htid'])
      # return shibURL + encodedURL
    rescue
      return nil
    end
  end

  def format_temp_location_note(temp_location)
    label_text = location = ''

    # This is the old behavior of backend, being replaced soon with Hash, below.
    if temp_location.is_a? String
      # hard-coded reliance on exact text of voyager_api
      what, shelved_in, location_name = temp_location.match(/(.*)(Shelved in)(.*)/i).captures
      label_text = "#{what}shelved in:"
    end

    if temp_location.is_a? Hash
      label_text = temp_location['itemLabel'] + ' shelved in:'
      location_name = temp_location['tempLocation']
    end

    label_text = label_text.strip.sub(/./, &:capitalize)
    label = content_tag(:span, label_text, class: 'holdings_label')
    location = format_location_link(location_name)

    label + location
  end

  def format_location_link(location_name)
    return '' unless location_name

    location = Location.match_location_text(location_name)

    # For some Location Names, do simple regexp string replacements
    replacements = APP_CONFIG['location_name_replacements'] || {}
    replacements.each_pair do |from, to|
      # Rails.logger.debug "location_name=#{location_name} from=#{from} to=#{to}"
      location_name.gsub!(/#{from}/, to)
    end
    return location_name unless location && location.category == 'physical'

    map_marker = content_tag(:span, ''.html_safe, class: 'glyphicon glyphicon-map-marker text-primary').html_safe
    location_link = link_to(map_marker + location_name, location_display_path(CGI.escape(location.name)), class: :location_display, target: '_blank')

    location_link
  end


  # ====  SCAN SERVICES  ====
  def campus_scan_link
    valet_url = APP_CONFIG['valet_url'] || 'https://valet.cul.columbia.edu'
    "#{valet_url}/campus_scan/"
  end


  # *** Valet service recap_scan needs both bib_id AND holding_id
  #     https://valet.cul.columbia.edu/recap_scan/2929292/10086
  def recap_scan_link
    valet_url = APP_CONFIG['valet_url'] || 'https://valet.cul.columbia.edu'
    "#{valet_url}/recap_scan/"
  end
  
  def offsite_link
    valet_url = APP_CONFIG['valet_url'] || 'https://valet.cul.columbia.edu'
    "#{valet_url}/offsite_requests/bib?bib_id="
  end

  def ill_scan_link
    valet_url = APP_CONFIG['valet_url'] || 'https://valet.cul.columbia.edu'
    "#{valet_url}/ill_scan/"
  end

  # NEXT-1819 - replace ill_link with ill_scan_link
  # def ill_link
  #   return APP_CONFIG['ill_link'] if APP_CONFIG['ill_link']
  #   'https://www1.columbia.edu/sec-cgi-bin/cul/forms/illiad?'
  # end
  
  # ====  PICK-UP SERVICES  ====

  def campus_paging_link
    valet_url = APP_CONFIG['valet_url'] || 'https://valet.cul.columbia.edu'
    "#{valet_url}/campus_paging/"
  end

  def fli_paging_link
    valet_url = APP_CONFIG['valet_url'] || 'https://valet.cul.columbia.edu'
    "#{valet_url}/fli_paging/"
  end

  # *** Valet service recap_loan needs both bib_id AND holding_id
  #     https://valet.cul.columbia.edu/recap_loan/2929292/10086
  def recap_loan_link
    valet_url = APP_CONFIG['valet_url'] || 'https://valet.cul.columbia.edu'
    "#{valet_url}/recap_loan/"
  end

  def borrow_direct_link
    valet_url = APP_CONFIG['valet_url'] || 'https://valet.cul.columbia.edu'
    "#{valet_url}/borrow_direct/"

    # # new simplified config approach
    # return APP_CONFIG['service_links']['borrow_direct'] if APP_CONFIG['service_links'] && APP_CONFIG['service_links']['borrow_direct']
    # # old config approach:
    # 'http://www.columbia.edu/cgi-bin/cul/borrowdirect?'
  end

  # ====  OTHER SERVICES  ====
  def barnard_remote_link
    valet_url = APP_CONFIG['valet_url'] || 'https://valet.cul.columbia.edu'
    "#{valet_url}/barnard_remote/"
  end

  def starrstor_link
    valet_url = APP_CONFIG['valet_url'] || 'https://valet.cul.columbia.edu'
    "#{valet_url}/starrstor/"
  end

  def avery_onsite_link
    valet_url = APP_CONFIG['valet_url'] || 'https://valet.cul.columbia.edu'
    "#{valet_url}/avery_onsite/"
  end

  def aeon_link
    aeon_url = APP_CONFIG['aeon_url'] || 'http://www.columbia.edu/cgi-bin/cul/aeon/request.pl'
    "#{aeon_url}?bibkey="
  end

  def precat_link
    #   'https://www1.columbia.edu/sec-cgi-bin/cul/forms/precat?'
    valet_url = APP_CONFIG['valet_url'] || 'https://valet.cul.columbia.edu'
    precat_link = APP_CONFIG['precat_link'] || "#{valet_url}/precat/"
  end

  def item_feedback_link
    valet_url = APP_CONFIG['valet_url'] || 'https://valet.cul.columbia.edu'
    item_feedback_link = APP_CONFIG['item_feedback_link'] || "#{valet_url}/item_feedback/"
  end

  def recall_hold_link
    # Valet Hold/Recall isn't ready
    return 'http://clio.cul.columbia.edu:7018/vwebv/patronRequests?sk=patron&bibId='

    if Rails.env == 'clio_prod'
      'http://clio.cul.columbia.edu:7018/vwebv/patronRequests?sk=patron&bibId='
    else
      valet_url = APP_CONFIG['valet_url'] || 'https://valet.cul.columbia.edu'
      return "#{valet_url}/recall_hold/"
    end
  end

  # "On Order" is handled identically to "In Process"
  def on_order_link
    # 'https://www1.columbia.edu/sec-cgi-bin/cul/forms/inprocess?'
    valet_url = APP_CONFIG['valet_url'] || 'https://valet.cul.columbia.edu'
    in_process_link = APP_CONFIG['in_process_link'] || "#{valet_url}/in_process/"
  end
  
  def in_process_link
    # 'https://www1.columbia.edu/sec-cgi-bin/cul/forms/inprocess?'
    valet_url = APP_CONFIG['valet_url'] || 'https://valet.cul.columbia.edu'
    in_process_link = APP_CONFIG['in_process_link'] || "#{valet_url}/in_process/"
  end


  # ====  SERVICES NOT MANAGED BY determine_services()/service_links()  ====
  
  def offsite_bound_with_url(title, enum_chron, barcode)
    return unless title.present? && barcode.present?

    valet_url = APP_CONFIG['valet_url']
    return unless valet_url.present?

    params = {
      barcode:             barcode,
      wanted_title:        title.first,
      wanted_enum_chron:   enum_chron
    }
    offsite_bound_with_url = "#{valet_url}/offsite_requests/barcode?#{params.to_query}"

    offsite_bound_with_url
  end

  def worldcat_link(document)
    return '' unless document

    # relied on reverse-engineering of WorldCat advanced search form,
    # and has proven unstable.
    # lookups = { 'oclc' => 'no', 'isbn' => 'bn', 'issn' => 'n2' }
    # lookups.each_pair do |key, field|

    # Use linking as documented at https://www.worldcat.org/wcpa/content/links
    ['oclc', 'isbn', 'issn'].each do |key|
      # extract_by_key will return nil or an array of ids
      next unless (ids = extract_by_key(document, key))
      # ids may have prefixes and hyphens, which need to be stripped
      # oclc:000123, isbn:1886-4805  ==>  000123, 18864805
      id = ids.first.gsub("#{key}:", '').gsub(/\-/, '')
      worldcat_url = get_worldcat_url(key, id)
      return content_tag(:a, 'Search for title in WorldCat', href: worldcat_url, class: 'worldcat_link')
    end
 
    # No usable keys found?  Then no link.
    return ''
  end

  # 
  # def worldcat_query_link(query)
  #   return '' unless query
  #   link = "https://worldcat.org/search?q=#{query}"
  #   link = content_tag(:a, 'Search for title in WorldCat', href: link, class: 'worldcat_link')
  # end
  
  def get_worldcat_url(key, id)
    return unless key && id
    return unless ['oclc', 'isbn', 'issn'].include? key
    id.gsub!(/\D/, '') if key == 'oclc'
    return "https://www.worldcat.org/#{key}/#{id}"
  end

end
