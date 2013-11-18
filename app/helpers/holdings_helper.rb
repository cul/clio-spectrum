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
    "Temporarily unavailable. Try Borrow Direct or ILL" =>
        "Temporarily Unavailable",
    "Butler Stacks (Enter at the Butler Circulation Desk)" =>
        "Butler Stacks",
    "Offsite - Place Request for delivery within 2 business days" =>
        "Offsite",
    "Offsite (Non-Circ) Request for delivery in 2 business days" =>
        "Offsite (Non-Circ)"
  }

  def shorten_location(location)
    SHORTER_LOCATIONS[location.strip] || location
  end

  # See NEXT-437 for discussion of presentation of call-number, location.
  # Some folks want to remove the '>>' delimeter, but this is (as of 10/13) 
  # still awaiting committee determination.
  def process_holdings_location(loc_display)
    loc, call = loc_display.split(' >> ')
    output = "".html_safe
    output << shorten_location(loc)  # append will html-escape content
    if call
      output << " >> "
      output << content_tag(:span, call, class: 'call_number').html_safe
    end
    output

    # old code:
    # call ? "#{h(shorten_location(loc))} >> ".html_safe + content_tag(:span, call, class: 'call_number')  : shorten_location(loc)
  end

  # Support for NEXT-113 - Do not make api request for online-only resources
  def has_physical_holdings?(document)
    # 'location' alone is only found in the 'location_facet' field, which is currently
    # indexed but not stored, so I can't use it.

    # Use the full 992b (location_call_number_id_display) and break it down redundantly here.
    # examples:
    #   Online >> EBOOKS|DELIM|13595275
    #   Lehman >> MICFICHE Y 3.T 25:2 J 13/2|DELIM|10465654
    #   Music Sound Recordings >> CD4384|DELIM|2653524
    return false unless location_call_number_id = document[:location_call_number_id_display]

    Array.wrap(location_call_number_id).each do |portmanteau|
      location = portmanteau.partition(' >>').first
      # If we find any location that's not Online, Yes, it's a physical holding
      return true if location and location != 'Online'
    end

    # If we dropped down without finding a physical holding, No, we have none
    return false
  end

  def online_link_hash(document)

    links = []
    # If we were passed, e.g., a Summon document object
    return links unless document.kind_of?(SolrDocument)

    document["url_munged_display"].listify.each do |url_munge|

      # See parsable_856s.bsh for the serialization code, which we here undo
      delim = '|||'
      url_parts = url_munge.split(delim).collect(&:strip)
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
          " (version of resource)"
        when '2'
          " (related resource)"
        else "" # omit note for ind2 == 0, the actual resource
      end
      url   = subfieldU

      # links << [title, note, url]   # as ARRAY
      links << { :title => title, :note => note, :url => url }  # as HASH

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

    if links.select { |link| link[:title].to_s.strip == "Google" }.length > 1
      links.reject! { |link| link[:title].to_s.strip == "Google" }
    end


    links
#    links.sort { |x,y| x.first <=> y.first }
  end


  SERVICE_ORDER = %w{offsite spec_coll precat recall_hold on_order borrow_direct ill in_process doc_delivery}
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
  #   'doc_delivery' => ['Document Delivery', " https://www1.columbia.edu/sec-cgi-bin/cul/forms/docdel?", true]
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
    'offsite' => ["Offsite",
        "http://www.columbia.edu/cgi-bin/cul/offsite2?"],
    'spec_coll' => ["Special Collections",
        "http://www.columbia.edu/cgi-bin/cul/aeon/request.pl?bibkey="],
    'precat' => ["Precataloging",
        "OpenPrecatRequest"],
    'recall_hold' => ["Recall / Hold",
        "http://clio.cul.columbia.edu:7018/vwebv/patronRequests?sk=patron&bibId="],
    'on_order' => ["On Order",
        "OpenInprocessRequest"],
    'borrow_direct' => ['Borrow Direct',
        "http://www.columbia.edu/cgi-bin/cul/borrowdirect?"],
    'ill' => ['ILL',
        "https://www1.columbia.edu/sec-cgi-bin/cul/forms/illiad?"],
    'in_process' => ['In Process',
        "OpenInprocessRequest"],
    'doc_delivery' => ['Scan & Deliver',
        "https://www1.columbia.edu/sec-cgi-bin/cul/forms/docdel?"]
  }

  def service_links(services, clio_id)
    services.select {|svc| SERVICE_ORDER.index(svc)}.sort_by { |svc| SERVICE_ORDER.index(svc) }.collect do |svc|
      title, link = SERVICES[svc]
      bibid = clio_id.to_s
      if link.match(/^http/)
        link += bibid
        link_to title, link, :target => "_blank"
      else
        jscript = "#{link}(#{bibid}); return false;"
        link_to title, "#", :onclick => jscript
      end
    end
  end


  def process_online_title(title)
    title.to_s.gsub(/^Full text available from /, '').gsub(/(\d{1,2})\/\d{1,2}(\/\d{4})/,'\1\2')
  end

  def add_display_elements(entries)
    entries.each do |entry|

      # location links
      location = Location.match_location_text(entry['location_name'])
      entry['location'] = location

      if location && location.category == "physical"
        check_at = DateTime.now
        entry['location_link'] = link_to(entry['location_name'], location_display_path(CGI.escape(entry['location_name'])), :class => :location_display)
      else
        entry['location_link'] = entry['location_name']
      end

      if location && location.library && (hours = location.library.hours.find_by_date(Date.today))
        entry['hours'] = hours.to_opens_closes
      end

      # add status icons
      entry['copies'].each do |copy|
        copy['items'].each_pair do |message,details|
          details['image_link'] = image_tag("icons/" + details['status'] + ".png")
        end
      end

    end

    sort_item_statuses(entries)

    entries

  end

  ITEM_STATUS_RANKING = ['available', 'some_available', 'not_available', 'none', 'online']

  def sort_item_statuses(entries)

    entries.each do |entry|
      entry['copies'].each do |copy|
        items = copy['items']
        copy['items'] = items.sort_by { |k,v| ITEM_STATUS_RANKING.index(v['status']) }
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

    unless document["isbn_display"].nil?
      bibkeys << Array.wrap(document["isbn_display"]).collect { |isbn| "isbn:" + isbn}.uniq
    end

    unless document["issn_display"].nil?
      bibkeys << Array.wrap(document["issn_display"]).collect { |issn| "issn:" + issn}.uniq
    end

    unless document["oclc_display"].nil?
      bibkeys << document["oclc_display"].collect { |oclc| "oclc:" + oclc.gsub(/^oc[mn]/,"") }.uniq
    end

    unless document["lccn_display"].nil?
      bibkeys << document["lccn_display"].collect { |lccn| "lccn:" + lccn.gsub(/\s/,"").gsub(/\/.+$/,"") }
    end

    bibkeys.flatten.compact

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
    return true

  end

end

