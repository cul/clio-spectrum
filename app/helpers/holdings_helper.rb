module HoldingsHelper

  SERVICE_ORDER = %w{offsite spec_coll precat recall_hold on_order borrow_direct ill in_process doc_delivery}
  # parameters: title, link, whether to append clio_id to link
  SERVICES = {
    'offsite' => ["Offsite", "http://www.columbia.edu/cgi-bin/cul/offsite2?", true],
    'spec_coll' => ["Special Collections", "http://www.columbia.edu/cgi-bin/cul/aeon/request.pl?bibkey=", true],
    'precat' => ["Precataloging", "https://www1.columbia.edu/sec-cgi-bin/cul/forms/Sprecat?", true],
    'recall_hold' => ["Recall/Hold", "http://clio.cul.columbia.edu:7018/vwebv/patronRequests?bibId=", true],
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

  def extract_google_bibkeys(document)
    
    bibkeys = []
    
    unless document["isbn_display"].nil?
      bibkeys << document["isbn_display"]
    end
    
    unless document["oclc_display"].nil?
      bibkeys << document["oclc_display"].collect { |oclc| "OCLC:" + oclc.gsub(/^oc[mn]/,"") }.uniq
    end
    
    unless document["lccn_display"].nil?
      bibkeys << document["lccn_display"].collect { |lccn| "LCCN:" + lccn.gsub(/\s/,"").gsub(/\/.+$/,"") }
    end
    
    bibkeys.flatten

  end

end

