module HoldingsHelper

  def condense_holdings(document_id)
    holdings = nil
    
    begin 
      holdings = Voyager::Holdings::Collection.new_from_opac(document_id)
    rescue
      return []
    end
    
    if determine_complexity(holdings) == :simple
      process_simple_holdings(holdings)
    else
      process_complex_holdings(holdings)
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

  def process_simple_holdings(holdings)
    
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

    entries
        
  end

  def process_complex_holdings(holdings)
    
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
    
    entries
    
  end

end

