# encoding: utf-8
module HoldingsHelper
  # unused function
  #   def build_holdings_hash(document)
  #     results = Hash.new { |h,k| h[k] = []}
  #     Holding.new(document["clio_id_display"]).fetch_from_opac!.
  #       results["holdings"].each_pair do |holding_id, holding_hash|
  #           results[[holding_hash["location_name"],holding_hash["call_number"]]] << holding_hash
  #     end
  #
  #     if document["url_munged_display"] && !results.keys.any? { |k| k.first.strip == "Online" }
  #       results[["Online", "ONLINE"]] = [{"call_number" => "ONLINE", "status" => "noncirc", "location_name" => "Online"}]
  #     end
  #     results
  #   end

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
              else '' # omit note for ind2 == 0, the actual resource
      end
      url = subfieldU

      # links << [title, note, url]   # as ARRAY
      links << { title: title, note: note, url: url } # as HASH
    end

    # remove google links if more than one exists

    if links.select { |link| link[:title].to_s.strip == 'Google' }.length > 1
      links.reject! { |link| link[:title].to_s.strip == 'Google' }
    end

    links
    #    links.sort { |x,y| x.first <=> y.first }
  end

  SERVICE_ORDER = %w(offsite barnard_remote spec_coll precat on_order borrow_direct borrow_direct_test recall_hold ill in_process doc_delivery).freeze

  # parameters: title, link (url or javascript), optional extra param
  # When 2nd param is a JS function,
  # that function will be called with two args: current bib-id and extra param
  # SERVICES = {
  def serviceConfig
    # just return a hash, the same as the constant did, but
    # now we can call methods as we build the config.
    {
      'offsite' => ['Offsite', 'OpenURLinWindow', offsite_link],

      'barnard_remote' => ['BearStor', 'OpenURLinWindow', barnard_remote_link],

      'spec_coll' => ['Special Collections',
                      'http://www.columbia.edu/cgi-bin/cul/aeon/request.pl?bibkey='],
      # 'precat' => %w(Precataloging OpenPrecatRequest),
      'precat' => ['Precataloging', 'OpenURLinWindow', precat_link],
      # 'recall_hold' => ['Recall / Hold',
      #                   'http://clio.cul.columbia.edu:7018/vwebv/patronRequests?sk=patron&bibId='],
      'recall_hold' => ['Recall / Hold', recall_hold_link],

      'on_order' => ['On Order',
                     'OpenInprocessRequest'],
      # 'borrow_direct' => ['Borrow Direct',
      #                     'http://www.columbia.edu/cgi-bin/cul/borrowdirect?'],
      'borrow_direct' => ['Borrow Direct', borrow_direct_link],
      # 'ill' => ['ILL',
      #           'https://www1.columbia.edu/sec-cgi-bin/cul/forms/illiad?'],
      'ill' => ['ILL', ill_link],
      'in_process' => ['In Process',
                       'OpenInprocessRequest'],
      'doc_delivery' => ['Scan & Deliver',
                         'https://www1.columbia.edu/sec-cgi-bin/cul/forms/docdel?']
    }
  end

  def service_links(services, clio_id)
    return [] unless services && clio_id

    services.select { |svc| SERVICE_ORDER.index(svc) }.sort_by { |svc| SERVICE_ORDER.index(svc) }.map do |svc|
      # title, link, extra = SERVICES[svc]
      title, link, extra = serviceConfig[svc]
      bibid = clio_id.to_s
      # URL services
      if link =~ /^http/
        link += bibid
        link_to title, link, target: '_blank'
      else
        # JavaScript services (open url in pop-up window)
        # Some functions (e.g., Valet) accept additional arg to pass along to the JS function
        js_function = extra.present? ? "#{link}('#{bibid}', '#{extra}')" : "#{link}('#{bibid}')"
        onclick_js = "#{js_function}; return false;"
        link_to title, '#', onclick: onclick_js.html_safe
      end
    end
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
          status_image = 'icons/' + details['status'] + '.png'
          status_label = details['status'].humanize
          # details['image_link'] = image_tag('icons/' + details['status'] + '.png')
          details['image_link'] = image_tag(status_image, title: status_label, alt: status_label)
        end
      end
    end

    sort_item_statuses(entries)

    entries
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

    Array.wrap(display_values).map do |value|
      # always remove all white-space from any key
      value.gsub!(/\s/, '')
      # LCCN sometimes has a strange suffix.  Remove it.
      # e.g., "84162131 /HE" or "78309771 //r83"
      value.gsub!(/\/.+$/, '') if value == 'lccn'
      # For OCLC numbers, strip away the prefix ('ocm' or 'ocn')
      value.gsub!(/^oc[mn]/, '') if value == 'oclc'
      # Here's what we want returned - key:value, e.g.
      "#{key}:#{value}"
    end
  end

  def extract_standard_bibkeys(document)
    bibkeys = []

    bibkeys << extract_by_key(document, 'isbn')
    bibkeys << extract_by_key(document, 'issn')
    bibkeys << extract_by_key(document, 'oclc')
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

      hathi_holdings_data = fetch_hathi_brief(id_type, id_value)
      break unless hathi_holdings_data.nil?
    end

    hathi_holdings_data
  end

  def fetch_hathi_brief(id_type, id_value)
    return nil unless id_type && id_value

    hathi_brief_url = 'http://catalog.hathitrust.org/api/volumes' \
                      "/brief/#{id_type}/#{id_value}.json"
    http_client = HTTPClient.new
    http_client.connect_timeout = 5 # default 60
    http_client.send_timeout    = 5 # default 120
    http_client.receive_timeout = 5 # default 60

    Rails.logger.debug "fetch_hathi_brief() get_content(#{hathi_brief_url})"
    begin
      json_data = http_client.get_content(hathi_brief_url)
      hathi_holdings_data = JSON.parse(json_data)

      # Hathi will pass back a valid, but empty, response.
      #     {"records"=>{}, "items"=>[]}
      # This means no hit with this bibkey, so return nil.
      return nil unless hathi_holdings_data &&
                        hathi_holdings_data['records'] &&
                        !hathi_holdings_data['records'].empty?

      # NEXT-1357 - Only display 'Full View' Hathi Trust records
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

    # This shouldn't happen - location_name should already be the display-label
    # # ReCAP partner locations
    # # Just a label now, but we could link to some kind of info box/page
    # if location_name.starts_with? 'scsb'
    #   return TrajectUtility.recap_location_code_to_label(location_name)
    # end

    location = Location.match_location_text(location_name)
    return location_name unless location && location.category == 'physical'

    map_marker = content_tag(:span, ''.html_safe, class: 'glyphicon glyphicon-map-marker text-primary').html_safe
    location_link = link_to(map_marker + location_name, location_display_path(CGI.escape(location.name)), class: :location_display, target: '_blank')

    location_link
  end

  def borrow_direct_link
    # new simplified config approach
    return APP_CONFIG['service_links']['borrow_direct'] if APP_CONFIG['service_links'] && APP_CONFIG['service_links']['borrow_direct']
    # old config approach:
    if Rails.env == 'clio_prod'
      'http://www.columbia.edu/cgi-bin/cul/borrowdirect?'
    else
      valet_url = APP_CONFIG['valet_url'] || 'https://valet.cul.columbia.edu'
      return "#{valet_url}/borrowdirect/"
    end
  end

  def recall_hold_link
    if Rails.env == 'clio_prod'
      'http://clio.cul.columbia.edu:7018/vwebv/patronRequests?sk=patron&bibId='
    else
      valet_url = APP_CONFIG['valet_url'] || 'https://valet.cul.columbia.edu'
      return "#{valet_url}/recall_hold/"
    end
  end

  def precat_link
    if Rails.env == 'clio_prod'
      'https://www1.columbia.edu/sec-cgi-bin/cul/forms/precat?'
    else
      valet_url = APP_CONFIG['valet_url'] || 'https://valet.cul.columbia.edu'
      return "#{valet_url}/precat/"
    end
  end

  def ill_link
    if Rails.env == 'clio_prod'
      'https://www1.columbia.edu/sec-cgi-bin/cul/forms/illiad?'
    else
      valet_url = APP_CONFIG['valet_url'] || 'https://valet.cul.columbia.edu'
      return "#{valet_url}/ill/"
    end
  end

  def intercampus_link
    if Rails.env == 'clio_prod' 
      'http://www.columbia.edu/cgi-bin/cul/resolve?lweb0013#'
    else
      valet_url = APP_CONFIG['valet_url'] || 'https://valet.cul.columbia.edu'
      return "#{valet_url}/intercampus/"
    end
  end

  def offsite_link
    valet_url = APP_CONFIG['valet_url'] || 'https://valet.cul.columbia.edu'
    "#{valet_url}/offsite_requests/bib?bib_id="
  end

  def barnard_remote_link
    valet_url = APP_CONFIG['valet_url'] || 'https://valet.cul.columbia.edu'
    # return "#{valet_url}/barnard_remote_requests/bib?bib_id="
    "#{valet_url}/bearstor/"
  end

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
end
