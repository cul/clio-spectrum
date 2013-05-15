# encoding: utf-8
module HoldingsHelper
  def build_holdings_hash(document)
    results = Hash.new { |h,k| h[k] = []}
    Holding.new(document["clio_id_display"]).fetch_from_opac!.results["holdings"].each_pair do |holding_id, holding_hash|
      results[[holding_hash["location_name"],holding_hash["call_number"]]] << holding_hash
    end

    if document["url_munged_display"] && !results.keys.any? { |k| k.first.strip == "Online" }
      results[["Online", "ONLINE"]] = [{"call_number" => "ONLINE", "status" => "noncirc", "location_name" => "Online"}]
    end
    results
  end

  SHORTER_LOCATIONS = {
    "Temporarily unavailable. Try Borrow Direct or ILL" => "Temporarily Unavailable",
    "Butler Stacks (Enter at the Butler Circulation Desk)" => "Butler Stacks",
    "Offsite - Place Request for delivery within 2 business days" => "Offsite",
    "Offsite (Non-Circ) Request for delivery in 2 business days" => "Offsite (Non-Circ)"
  }

  def shorten_location(location)
    SHORTER_LOCATIONS[location.strip] || location

  end

  def process_holdings_location(loc_display)
    loc,call = loc_display.split(' >> ')
    call ? "#{h(shorten_location(loc))} >> ".html_safe + content_tag(:span, call, class: 'call_number')  : shorten_location(loc)
  end

  URL_REGEX = Regexp.new('(?i)\b((?:[a-z][\w-]+:(?:/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:\'".,<>?«»“”‘’]))')


  def online_link_hash(document)

    links = []

    document["url_munged_display"].listify.each do |url_munge|
      url_parts = url_munge.split('~|Z|~').collect(&:strip)
      title = url =  ""
      if (url_index = url_parts.index { |part| part =~ URL_REGEX })
        url = url_parts.delete_at(url_index)
        title = url_parts.join(" ").to_s
        title = url if title.empty?
      else
        title = "Bad URL: " + url_parts.join(" ")
        url = ""
      end

      links << [title, url]
    end

    # remove google links if more than one exists

    if links.select { |link| link.first.to_s.strip == "Google" }.length > 1
      links.reject! { |link| link.first.to_s.strip == "Google" }
    end


    links
#    links.sort { |x,y| x.first <=> y.first }
  end


  SERVICE_ORDER = %w{offsite spec_coll precat recall_hold on_order borrow_direct ill in_process doc_delivery}
  # parameters: title, link, whether to append clio_id to link
  SERVICES = {
    'offsite' => ["Offsite", "http://www.columbia.edu/cgi-bin/cul/offsite2?", true],
    'spec_coll' => ["Special Collections", "http://www.columbia.edu/cgi-bin/cul/aeon/request.pl?bibkey=", true],
    'precat' => ["Precataloging", "https://www1.columbia.edu/sec-cgi-bin/cul/forms/Sprecat?", true],
    'recall_hold' => ["Recall/Hold", "http://clio.cul.columbia.edu:7018/vwebv/patronRequests?sk=patron&bibId=", true],
    'on_order' => ["On Order", "https://www1.columbia.edu/sec-cgi-bin/cul/forms/Sinprocess?", true],
    'borrow_direct' => ['Borrow Direct', "http://www.columbia.edu/cgi-bin/cul/borrowdirect?", true],
    'ill' => ['ILL', "https://www1.columbia.edu/sec-cgi-bin/cul/forms/illiad?", true],
    'in_process' => ['In Process', "https://www1.columbia.edu/sec-cgi-bin/cul/forms/Sinprocess?", true],
    'doc_delivery' => ['Document Delivery', " https://www1.columbia.edu/sec-cgi-bin/cul/forms/docdel?", true]
  }

  def service_links(services, clio_id, options = {})
    services.select {|svc| SERVICE_ORDER.index(svc)}.sort_by { |svc| SERVICE_ORDER.index(svc) }.collect do |svc|
      title, uri, add_clio_id = SERVICES[svc]
      uri += clio_id.to_s if add_clio_id
      link_to title, uri, options
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

end

