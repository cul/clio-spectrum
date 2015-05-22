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
  }

  def shorten_location(location)
    SHORTER_LOCATIONS[location.strip] || location
  end

  def process_holdings_location(loc_display)
    location, call_number = loc_display.split(' >> ')
    output = ''.html_safe
    output << shorten_location(location)  # append will html-escape content
    if call_number
      # NEXT-437 - remove the separator between location and call number
      # output << " >> "
      output << content_tag(:span, " #{call_number} ", class: 'call_number').html_safe
    end
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
      return true if location and location != 'Online'
    end

    # If we dropped down without finding a physical holding, No, we have none
    false
  end

  # Detect Law records, cataloged in Pegasus (http://pegasus.law.columbia.edu/)
  def in_pegasus?(document)
    # raise
    # Document must have an id, which must be a "b" followed by a number...
    return false unless document.id and document.id.match /^b\d{3,9}$/

    # And, confirm that the Location is "Law"

    # pull out the Location/call-number/holdings-id field...
    return false unless location_call_number_id = document[:location_call_number_id_display]
    # unpack, and confirm each occurrance ()
    Array.wrap(location_call_number_id).each do |portmanteau|
      location = portmanteau.partition(' >>').first
      # If we find any location that's not Law, this is NOT pegasus
      return false if location and location != 'Law'
    end

    true
  end

  def online_link_hash(document)
    links = []
    # If we were passed, e.g., a Summon document object
    return links unless document.kind_of?(SolrDocument)

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

      return links unless subfieldU =~ url_regex

      title = "#{subfield3} #{subfieldZ}".strip
      title = subfieldU unless title.length > 0
      note  = case ind2
        when '1'
          ' (version of resource)'
        when '2'
          ' (related resource)'
        else '' # omit note for ind2 == 0, the actual resource
      end
      url   = subfieldU

      # links << [title, note, url]   # as ARRAY
      links << { title: title, note: note, url: url }  # as HASH

      # url_parts = url_munge.split('~|Z|~').collect(&:strip)
      # title = url =  ""
      # if (url_index = url_parts.index { |part| part =~ URL_REGEX })
      #   url = url_parts.delete_at(url_index)
      #   title = url_parts.join(" ").to_s
      #   title = url if title.empty?
      #   links << [title, url]
      # # Actually, just ignore bad URLs, don't display in the interface
      # # else
      # #   title = "Bad URL: " + url_parts.join(" ")
      # #   url = ""
      # end

    end

    # remove google links if more than one exists

    if links.select { |link| link[:title].to_s.strip == 'Google' }.length > 1
      links.reject! { |link| link[:title].to_s.strip == 'Google' }
    end

    links
#    links.sort { |x,y| x.first <=> y.first }
  end

  SERVICE_ORDER = %w(offsite spec_coll precat recall_hold on_order borrow_direct ill in_process doc_delivery)
  # # parameters: title, link, whether to append clio_id to link
  # SERVICES = {
  #   'offsite' => ["Offsite", "http://www.columbia.edu/cgi-bin/cul/offsite2?", true],
  #   'spec_coll' => ["Special Collections", "http://www.columbia.edu/cgi-bin/cul/aeon/request.pl?bibkey=", true],
  #   'precat' => ["Precataloging", "https://www1.columbia.edu/sec-cgi-bin/cul/forms/Sprecat?", true],
  #   'recall_hold' => ["Recall/Hold", "http://clio.cul.columbia.edu:7018/vwebv/patronRequests?sk=patron&bibId=", true],
  #   'on_order' => ["On Order", "https://www1.columbia.edu/sec-cgi-bin/cul/forms/Sinprocess?", true],
  #   'borrow_direct' => ['Borrow Direct', "http://www.columbia.edu/cgi-bin/cul/borrowdirect?", true],
  #   'ill' => ['ILL', "https://www1.columbia.edu/sec-cgi-bin/cul/forms/illiad?", true],
  #   'in_process' => ['In Process', "https://www1.columbia.edu/sec-cgi-bin/cul/forms/Sinprocess?", true],
  #   'doc_delivery' => ['Document Delivery', "https://www1.columbia.edu/sec-cgi-bin/cul/forms/docdel?", true]
  # }
  #
  # def service_links(services, clio_id, options = {})
  #   services.select {|svc| SERVICE_ORDER.index(svc)}.sort_by { |svc| SERVICE_ORDER.index(svc) }.collect do |svc|
  #     title, uri, add_clio_id = SERVICES[svc]
  #     uri += clio_id.to_s if add_clio_id
  #     link_to title, uri, options
  #   end
  # end

  # parameters: title, link (url or javascript)
  SERVICES = {
    'offsite' => ['Offsite',
                  'http://www.columbia.edu/cgi-bin/cul/offsite2?'],
    'spec_coll' => ['Special Collections',
                    'http://www.columbia.edu/cgi-bin/cul/aeon/request.pl?bibkey='],
    'precat' => %w(Precataloging OpenPrecatRequest),
    'recall_hold' => ['Recall / Hold',
                      'http://clio.cul.columbia.edu:7018/vwebv/patronRequests?sk=patron&bibId='],
    'on_order' => ['On Order',
                   'OpenInprocessRequest'],
    'borrow_direct' => ['Borrow Direct',
                        'http://www.columbia.edu/cgi-bin/cul/borrowdirect?'],
    'ill' => ['ILL',
              'https://www1.columbia.edu/sec-cgi-bin/cul/forms/illiad?'],
    'in_process' => ['In Process',
                     'OpenInprocessRequest'],
    'doc_delivery' => ['Scan & Deliver',
                       'https://www1.columbia.edu/sec-cgi-bin/cul/forms/docdel?']
  }

  def service_links(services, clio_id)
    return [] unless services && clio_id

    services.select { |svc| SERVICE_ORDER.index(svc) }.sort_by { |svc| SERVICE_ORDER.index(svc) }.map do |svc|
      title, link = SERVICES[svc]
      bibid = clio_id.to_s
      if link.match(/^http/)
        link += bibid
        link_to title, link, target: '_blank'
      else
        jscript = "#{link}(#{bibid}); return false;"
        link_to title, '#', onclick: jscript
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

      # location links
      location = Location.match_location_text(entry['location_name'])
      entry['location'] = location

      if location && location.category == 'physical'
        # NEXT-1041 - Icon or other visual cue
        # %span.glyphicon.glyphicon-map-marker.text-primary
        map_marker = content_tag(:span, "".html_safe, class: 'glyphicon glyphicon-map-marker text-primary').html_safe

        entry['location_link'] = link_to(map_marker + entry['location_name'], location_display_path(CGI.escape(entry['location_name'])), class: :location_display)
      else
        entry['location_link'] = entry['location_name']
      end

      if location && location.library && (hours = location.library.hours.find_by_date(Date.today))
        entry['hours'] = hours.to_opens_closes
      end

      # location notes
      # "additional" are from app_config, or hard-coded application logic (e.g., pegasus)
      more_notes = additional_holdings_location_notes(nil, entry['location_name'])
      # There might already be location notes - if so, append.
      if entry['location_note']
        entry['location_note'] = Array.wrap(entry['location_note'].html_safe)
      else
        entry['location_note'] = []
      end
      # entry['location_note'].html_safe if entry['location_note']
      # entry['location_note'] = Array.wrap(entry['location_note'])
      entry['location_note'].concat(more_notes) if (more_notes && more_notes.size > 0)

      # add status icons
      entry['copies'].each do |copy|
        copy['items'].each_pair do |message, details|
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

  ITEM_STATUS_RANKING = %w(available some_available not_available none online)

  def sort_item_statuses(entries)
    entries.each do |entry|
      entry['copies'].each do |copy|
        items = copy['items']
        copy['items'] = items.sort_by { |k, v| ITEM_STATUS_RANKING.index(v['status']) }
      end
    end

    # NOTE: This sort_by step changes the copy[:items] structure from:
    #       {message => {:status => , :count => , etc.}, ...}
    #     to:
    #       [[message, {:status => , :count => , etc.}], ...]
    # in order to preserve the sort order.
  end

  def extract_standard_bibkeys(document)
    bibkeys = []

    unless document['isbn_display'].nil?
      bibkeys << Array.wrap(document['isbn_display']).map { |isbn| 'isbn:' + isbn }.uniq
    end

    unless document['issn_display'].nil?
      bibkeys << Array.wrap(document['issn_display']).map { |issn| 'issn:' + issn }.uniq
    end

    unless document['oclc_display'].nil?
      bibkeys << document['oclc_display'].map { |oclc| 'oclc:' + oclc.gsub(/^oc[mn]/, '') }.uniq
    end

    unless document['lccn_display'].nil?
      bibkeys << document['lccn_display'].map { |lccn| 'lccn:' + lccn.gsub(/\s/, '').gsub(/\/.+$/, '') }
    end

    # Some Hathi records were directly loaded into Voyager.
    # These have direct Hathi links in their 856 - and these
    # links have a standard ID number not otherwise available.
    online_link_hash(document).each do |link|
      next unless link[:url].start_with? "http://catalog.hathitrust.org"
      unless link[:url].match( /api\/volumes\/\w+\/\d+.html/ )
        # Rails.logger.debug "bib #{document.id} unexpected URL #{link[:url]}"
        next
      end
      # Rails.logger.debug "bib #{document.id} as-expected URL #{link[:url]}"

      id_type, id_value = link[:url].match( /api\/volumes\/(\w+)\/(\d+).html/ ).captures

      # put at the front - so later first-found processing hits this one
      bibkeys.unshift(id_type + ':' + id_value)
    end

    # Sometimes the document data from Solr has invalid chars in the bib keys.
    # Strip these out so they don't trip up any code which uses these bibkeys.
    bibkeys.flatten.compact.map { |bibkey|
      bibkey.gsub(/[^a-zA-Z0-9\:\-]/, '').strip
    }.uniq
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
      next unless id_type and id_value

      hathi_holdings_data = fetch_hathi_brief(id_type, id_value)
      break unless hathi_holdings_data.nil?
    end

    return hathi_holdings_data
  end

  def fetch_hathi_brief(id_type, id_value)
    return nil unless id_type and id_value

    hathi_brief_url = "http://catalog.hathitrust.org/api/volumes" +
                      "/brief/#{id_type}/#{id_value}.json"
    http_client = HTTPClient.new
    http_client.connect_timeout = 5 # default 60
    http_client.send_timeout    = 5 # default 120
    http_client.receive_timeout = 5 # default 60

    Rails.logger.debug "get_content(#{hathi_brief_url})"
    begin
      json_data = http_client.get_content(hathi_brief_url)
      hathi_holdings_data = JSON.parse(json_data)

      # Hathi will pass back a valid, but empty, response.
      #     {"records"=>{}, "items"=>[]}
      # This means no hit with this bibkey, so return nil.
      return nil unless hathi_holdings_data &&
                        hathi_holdings_data['records'] &&
                        hathi_holdings_data['records'].size > 0
      return hathi_holdings_data
    rescue => error
      logger.error "Error fetching #{hathi_brief_url}: #{error.message}"
      return nil
    end
  end

end

