module HoldingsHelper

  def condense_holdings(holdings)
    entries = [] 
    holdings.records.each do |record|
      entry = entries.find { |entry| entry[:location_name] == record.location_name }

      unless entry
        location = Location.match_location_text(record.location_name)

        entry = {
          :location_name => record.location_name,
          :call_number => record.call_number,
          :location => location,
          :items => {}
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

      messages = record.item_status[:messages]
      if entry[:items].has_key?(messages)
        entry[:items][messages][:count] += 1
      else
        entry[:items][messages] = {
          :status => record.item_status[:status],
          :image_link => image_tag("icons/" + record.item_status[:status] + ".png"),
          :count => 1
        }
      end

    end

    entries
  end

end

