module HoldingsHelper

  def condense_holdings(document_id)
    holdings = nil
    
    begin 
      holdings = Voyager::Holdings::Collection.new_from_opac(document_id)
    rescue
      return []
    end
    
    complexity = determine_complexity(holdings)
    
    if complexity == :simple
      process_simple_holdings(holdings)
    else
      process_complex_holdings(holdings)
    end
    
  end

  def determine_complexity(holdings)
    
    complexity = :simple
    holdings.records.each do |record|
      if !record.summary_holdings.empty? ||
          !record.temp_locations.empty?
        complexity = :complex
      end
    end
    
    complexity
      
  end

  def process_simple_holdings(holdings)
    
    entries = [] 
    holdings.records.each do |record|
      entry = entries.find { |entry| entry[:location_name] == record.location_name && 
        entry[:call_number] == record.call_number}

      unless entry
        location = Location.match_location_text(record.location_name)

        entry = {
          :location_name => record.location_name,
          :call_number => record.call_number,
          :location => location,
          :copies => [{:items => {}}]
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
        if entry[:copies][0][:items].has_key?(message)
          entry[:copies][0][:items][message][:count] += 1
        else
          entry[:copies][0][:items][message] = {
            :status => record.item_status[:status],
            :image_link => image_tag("icons/" + record.item_status[:status] + ".png"),
            :count => 1
          }
        end
      end

    end

    entries
        
  end

  def process_complex_holdings(holdings)
    
    entries = [] 
    holdings.records.each do |record|
      entry = entries.find { |entry| entry[:location_name] == record.location_name }

      unless entry
        location = Location.match_location_text(record.location_name)

        entry = {
          :location_name => record.location_name,
          :call_number => record.call_number,
          :location => location,
          :copies => []
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
      
      # summary holdings
      if !record.summary_holdings.empty?
        out[:summary_holdings] = "Library has: " + record.summary_holdings.join(' ')
      end
      
      # temp locations
      if !record.temp_locations.empty?
        out[:temp_locations] = record.temp_locations
      end
      
      entry[:copies] << out

    end
    
    entries
    
  end

end

