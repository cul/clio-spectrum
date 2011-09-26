module HoldingsHelper

  def retrieve_holdings(document)
    
    document_id = document.get('id')
    
    holdings = nil
    
    begin 
      holdings = Voyager::Holdings::Collection.new_from_opac(document_id)
    rescue
      return []
    end
    
    if determine_complexity(holdings) == :simple
      process_simple_holdings(holdings,document_id)
    else
      process_complex_holdings(holdings,document_id)
    end
    
  end

  def determine_complexity(holdings)
    
    # holdings are complex if anything other than item_status has a value
    
    complexity = :simple
    holdings.records.each do |record|
      if !record.summary_holdings.empty? ||
          !record.supplements.empty? ||
          !record.indexes.empty? ||
          !record.notes.empty? ||
          !record.reproduction_note.empty? ||
          !record.current_issues.empty? ||
          !record.temp_locations.empty? ||
          !record.orders.empty?
        complexity = :complex
      end
    end
    
    complexity
      
  end

  def process_simple_holdings(holdings,document_id)
    
    # for simple holdings item statuses for all copies for a location are grouped together
    # under each location
    
    entries = [] 
    holdings.records.each do |record|
      # test for location and call number
      entry = entries.find { |entry| entry[:location_name] == record.location_name && 
        entry[:call_number] == record.call_number}

      unless entry
        location = Location.match_location_text(record.location_name)

        entry = {
          :location_name => record.location_name,
          :call_number => record.call_number,
          :location => location,
          :copies => [{:items => {}}],
          :services => []
        }

        if location && location.category == "physical"
          check_at = DateTime.now
          entry[:location_link] = link_to(record.location_name, location_display_path(CGI.escape(record.location_name)), :class => :location_display)
        else
          entry[:location_link] = record.location_name
        end

        if location && location.library && (hours = location.library.hours.find_by_date(Date.today))
          entry[:hours] = hours.to_opens_closes
        end
        
        entries << entry
      end

      # for simple holdings put consolidated status information in the first copy

      messages = record.item_status[:messages]
      messages.each do |message|
        if entry[:copies].first[:items].has_key?(message)
          entry[:copies].first[:items][message][:count] += 1
        else
          entry[:copies].first[:items][message] = {
            :status => record.item_status[:status],
            :image_link => image_tag("icons/" + record.item_status[:status] + ".png"),
            :count => 1
          }
        end
      end

    end

    determine_services(entries,document_id)

    entries
        
  end

  def process_complex_holdings(holdings,document_id)
    
    # for complex holdings all available elements for each copy are collected together
    # and grouped by location
    
    entries = [] 
    holdings.records.each do |record|
      # test for location and call number
      entry = entries.find { |entry| entry[:location_name] == record.location_name && 
        entry[:call_number] == record.call_number}

      unless entry
        location = Location.match_location_text(record.location_name)

        entry = {
          :location_name => record.location_name,
          :call_number => record.call_number,
          :location => location,
          :copies => [],
          :services => []
        }

        if location && location.category == "physical"
          check_at = DateTime.now
          entry[:location_link] = link_to(record.location_name, location_display_path(CGI.escape(record.location_name)), :class => :location_display)
        else
          entry[:location_link] = record.location_name
        end

        if location && location.library && (hours = location.library.hours.find_by_date(Date.today))
          entry[:hours] = hours.to_opens_closes
        end
        
        entries << entry
      end

      # create out hash of elements for each copy and add to entry :copies array
      out = {}

      # process status messages
      messages = record.item_status[:messages]
      items = {}
      messages.each do |message|
        if items.has_key?(message)
          items[message][:count] += 1
        else
          items[message] = {
            :status => record.item_status[:status],
            :image_link => image_tag("icons/" + record.item_status[:status] + ".png"),
            :count => 1
          }
        end
      end
      out[:items] = items
      
      # current_issues
      unless record.current_issues.empty?
        out[:current_issues] = "Current Issues: " + record.current_issues.join('; ')
      end

      # indexes
      unless record.indexes.empty?
        out[:indexes] = "Indexes: " + record.indexes.join(' ')
      end

      # notes
      unless record.notes.empty?
        out[:notes] = "Notes: " + record.notes.join(' ')
      end

      # orders
      unless record.orders.empty?
        out[:orders] = "Order Information: " + record.orders.join('; ')
      end

      # reproduction note
      unless record.reproduction_note.empty?
        out[:reproduction_note] = record.reproduction_note
      end

      # supplements
      unless record.supplements.empty?
        out[:supplements] = "Supplements: " + record.supplements.join(' ')
      end

      # summary holdings
      unless record.summary_holdings.empty?
        out[:summary_holdings] = "Library has: " + record.summary_holdings.join(' ')
      end
      
      # temp locations
      unless record.temp_locations.empty?
        out[:temp_locations] = record.temp_locations
      end
      
      entry[:copies] << out

    end
    
    determine_services(entries,document_id)

    entries
    
  end

  def determine_services(entries,document_id)
    
    entries.each do |entry|
      
      next if entry[:location_name].match(/^Online/)
      
      status, messages = get_overall_status(entry[:copies])

      if status == :available
        # offsite
        if entry[:location_name].match(/^Offsite/) &&
            HTTPClient.new.get_content("http://www.columbia.edu/cgi-bin/cul/lookupNBX?" + document_id) == "1"
          entry[:services] << 'offsite'
        end
        # precat
        if entry[:location_name].match(/^Precat/)
          entry[:services] << 'precat'
        end
      elsif status == :some_available
        if entry[:location_name].match(/^Offsite/) &&
            HTTPClient.new.get_content("http://www.columbia.edu/cgi-bin/cul/lookupNBX?" + document_id) == "1"
          entry[:services] << 'offsite'
        end         
        services = scan_messages(messages)
        entry[:services] += services unless services.empty?
      elsif status == :none
        entry[:services] << 'in_process' if entry[:call_number].match(/in process/i)
      else 
        services = scan_messages(messages)
        entry[:services] += services unless services.empty?
      end

#      entry[:services] << messages

    end
    
  end

  def get_overall_status(copies)
    
    a = 0   # available
    s = 0   # some available
    n = 0   # not available
    
    messages = []
    status = ''
    
    copies.each do |copy|
      # on order / in process messages
      messages << copy[:orders] unless copy[:orders].nil?
      # statuses
      copy[:items].each_pair do |message,details|
        messages << message
        a = 1 if details[:status] == 'available'
        s = 2 if details[:status] == 'some_available'
        n = 4 if details[:status] == 'not_available'
      end
    end
    
    #               |  some           |  not
    # available (1) |  available (2)  |  available (4)    total (a+s+n)
    # -----------------------------------------------------------------
    #     Y               Y                 Y               7
    #     Y               Y                 N               3
    #     Y               N                 Y               5
    #     Y               N                 N               1
    #     N               Y                 Y               6
    #     N               Y                 N               2
    #     N               N                 Y               4
    #     N               N                 N               0
    #
    # :available is returned if all items are available (1).
    # :not_available is returned if everything is unavailable (4).
    # :none is returned if there is no status (0).
    # otherwise :some_available is returned:
    # All status are checked; as long as something is available, even if
    # there are some items check out, :some_available is returned.
    # Messages are cleared out if there are any copies available.
    #
    # All of these distinction may not be needed.
    
    case a + s + n
    when 0
      status = :none
    when 1
      status = :available
    when 3
      status = :some_available
      messages.clear
    when 4
      status = :not_available
    when 5
      status = :some_available
      messages.clear
    when 7
      status = :some_available
      messages.clear
    else
      status = :some_available
    end

    [status, messages]

  end

  def scan_messages(messages)
    
    out = []
    messages.each do |message|
      out << 'recall_hold' if message =~ /Recall/i
      out << 'recall_hold' if message =~ /hold /
      out << 'borrow_direct' if message =~ /Borrow/
      out << 'ill' if message =~ /ILL/
      out << 'in_process' if message =~ /In Process/
    end
    
    out.uniq
    
  end
  
end

