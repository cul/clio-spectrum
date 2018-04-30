module Voyager
  module Holdings
    class Item
      attr_reader :holding_id, :item_count, :temp_locations, :use_restrictions, :item_status

      # Item class initializing method
      def initialize(mfhd_id, holdings_marc, mfhd_status, scsb_status)

        @holding_id = mfhd_id

        # mfhd_status is a hash map of item-id to item-detail-hash
        # {
        #   7814714: {
        #     holdLocation: "",
        #     itemLabel: "",
        #     requestCount: 0,
        #     statusCode: 1,
        #     statusDate: "2017-07-27",
        #     statusPatronMessage: ""
        #   }
        # }
        
        # scsb_status is a hash map of barcode-to-ReCAP availability
        # {
        #   "CU18799175"  =>  "Available"
        # }
        
        @item_count = 0
        holdings_marc.each_by_tag('876') do |t876|
          @item_count = @item_count + 1

          item_id = t876['a']
          barcode = t876['p']

          # If Voyager holdings status doesn't yet have an entry for this item id, 
          # create it.  (This shouldn't happen.)  
          # Try creating empty hash.  We'll insert default keys/values if we find we need some.
          unless mfhd_status[item_id].present?
            mfhd_status[item_id] = { }
          end
          
          # If SCSB holds a status for this item, then it's an offsite item.
          # SCSB availability status may be:  Available, Unavailable, Not Available (?)
          case scsb_status[ barcode ]

          # Available, status code 1
          when 'Available'
            mfhd_status[item_id][:statusCode] = 1

          # NEXT-1447
          # - If it's Unavailable, but Voyager doesn't know it, it's a partner checkout
          # - If it's Unavailable, and Voyager knows it's not available (not status code == 1), 
          #   then just defer to Voyager - leave the mfhd status code as-is, don't overwrite.
          when 'Unavailable', 'Not Available'
            # If Voyager has no status, or Voyager says "1" (available), it's a partner checkout
            if mfhd_status[item_id][:statusCode].nil? || (mfhd_status[item_id][:statusCode] == 1)
              # Special "99" status code for ReCAP checkouts
              mfhd_status[item_id][:statusCode] = 99
            end
            # Else, if Voyager Holdings status is non-1, then leave it as-is.  
            # (CUL offsite item checked out to CUL patron)
          end
          
          # Finally, if the statusCode could not be determined through any of the above logic,
          #  fill in a default of Unavailable - status code 13.
          # Not sure why this would happen.
          if mfhd_status[item_id][:statusCode].blank?
            mfhd_status[item_id][:statusCode] = 13
            Rails.logger.warn "No mfhd status code for holding_id #{mfhd_id}, item_id #{item_id}, barcode #{barcode} - defaulting to 'Unavailable'"
          end

        end


        @temp_locations = parse_for_temp_locations(holdings_marc)  # array
        @use_restrictions = parse_for_use_restrictions(holdings_marc)  # array
        @item_status = parse_for_circ_status(mfhd_status)  # hash
      end

      private

      # Isolates item:itemLocation nodes in the mfhd:itemCollection and
      # extracts information on items in temp locations.
      #
      # * *Args*    :
      #   - +item+ -> mfhd:itemCollection node
      #   - +location+ -> mfhd display location
      # * *Returns* :
      #   - An array of temp-location structures for items found in temp locations.  E.g.,
      #      [ { itemLabel: 'v.1-v.49', tempLocation: 'West Wing'}, { itemLabel: 'DVD', tempLocation: 'Media Lab' } ]
      #   - An empty array if there are no items in temp locations
      #
      def parse_for_temp_locations(holdings_marc)
        tempLocations = []

        holdings_marc.each_by_tag('876') do |t876|
          # subfield l has tempLocation
          if t876['l']
            tempLocations << { itemLabel: (t876['3'] || ''), tempLocation: t876['l'] }
          end
        end

        return tempLocations
      end

      def parse_for_use_restrictions(holdings_marc)
        useRestrictions = []

        item_count = 0
        notes = Hash.new()
        holdings_marc.each_by_tag('876') do |t876|
          item_count += 1
          # subfield h has Use Restrictions
          next unless t876['h'].present?

          note = t876['h']

          # Ignore these use restriction codes
          next if ['ENVE', 'TIED'].include? note

          # Map use restriction codes to notes
          note = 'In library use' if note == 'FRGL'
          
          if notes[note].present?
            notes[note] += 1 
          else
            notes[note] = 1 
          end
          
          # next unless t876['h']
          # if t876['h'] == 'FRGL'
          #   notes['In library use only'] != notes['In library use only']
          #   useRestrictions << 'In library use only.'
          # else
          #   useRestrictions << t876['h']
          # end
        end

        notes.each do |note, note_count|
          note = note.titleize
          if note_count == item_count
            useRestrictions << "#{note.titleize} Only"
          else
            useRestrictions << "Some items #{note} Only"
          end
        end
        
        return useRestrictions
      end

      # Isolates item:itemRecord nodes in the mfhd:itemCollection,
      # determines circulation status and generates messages
      #
      # * *Args*    :
      #   - +item+ -> mfhd:itemCollection node
      #   - +item_count+ -> count of item records
      # * *Returns* :
      #   - Hash containing overall circulation status and a list of circulation messages
      #     { :status => overall item status, :messages => [ one or more circulation messages ] }
      #   - Possible statuses are: 'none', 'available', 'not_available', 'some_avaialble'
      #   - An additional status, 'online', is set in the Record class
      #
      def parse_for_circ_status(mfhd_status)

        # no items = no status available
        if mfhd_status.size == 0
          return {:status => 'none',
                  :messages => [ {:status_code => '0',
                                  :short_message => 'Status unknown',
                                  :long_message => 'No item status available'} ]
                }
        end

        # determine overall status
        status = determine_overall_status(mfhd_status)
        # generate messages
        messages = generate_messages(mfhd_status)

        return {:status => status, :messages => messages }

      end

      # Set the overall circulation status
      #
      # * *Args*    :
      #   - +records+ -> Array of hashes for data in item:itemRecord nodes
      #   - +item_count+ -> count of item records
      # * *Returns* :
      #   - Overall circulation status
      #
      def determine_overall_status(mfhd_status)
        unavailable_count = 0
        mfhd_status.each do |item_id, item|
          statusCode = item[:statusCode].to_i
          unavailable_count += 1 if statusCode > 1 && statusCode != 11
        end

        case
        when unavailable_count == 0
          return 'available'
        when unavailable_count == mfhd_status.size
          return 'not_available'
        else
          return 'some_available'
        end
      end

      # Generate circulation messages
      #
      # * *Returns* :
      #   - Array of circulation messages
      #
      def generate_messages(mfhd_status)

        messages = []
        mfhd_status.each do |item_id, item|
          messages << generate_message(item)
        end
        messages
      end

      # Generate message from a record (item:itemRecord node)
      #
      # * *Args*    :
      #   - +record+ -> Hash of data from an item:itemRecord node
      # * *Returns* :
      #   - Formatted message in a hash
      #     :status_code => code of status message
      #     :short_message => short version of message
      #     :long_message => long version of message
      #
      def generate_message(item)
        short_message = ''
        long_message = ''
        code = ''
        # status patron message otherwise regular message
        if item[:statusPatronMessage].present?
          code = 'sp'
          long_message = item[:statusPatronMessage]
          short_message = long_message.gsub(/(Try|Place).+/, '').strip
          short_message = short_message.gsub(/\W$/, '')
        # if record[:patronGroupCode].strip.match(/^(IND|MIS|ACO)/)
        #   code = 'sp'
        #   long_message = record[:lastName].strip + ' ' + record[:firstName].strip
        #   # done in two steps in case ending puctuation is missing
        #   short_message = long_message.gsub(/(Try|Place).+/, '').strip
        #   short_message = short_message.gsub(/\W$/, '')
        else
          code = item[:statusCode].to_s
          # append suffix to indicate whether there are requests - n = no requests, r = requests
          if item[:requestCount] && item[:requestCount] > 0
            code += 'r'
          else
            code += 'n'
          end

          # get parms for the message being processed
          parms = ITEM_STATUS_CODES[code]

          raise "Status code [#{code}] not found in config/item_status_codes.yml" unless parms

          short_message = make_substitutions(parms['short_message'], item)
          # long_message = make_substitutions(parms['long_message'], item)

        end

        # add labels - but not for "Available" items
        short_message = add_label(short_message, item) unless short_message == 'Available'
        # long_message = add_label(long_message, item)

        # if Rails.env == 'clio_dev'
        #   short_message = short_message + " (status code #{code})"
        #   long_message = long_message + " (status code #{code})"
        # end

        return { :status_code => code,
                 :short_message => short_message,
                 :long_message => long_message }
      end


      def format_datetime(item)
        # format date / time
        datetime = ''
        if item[:statusDate].present?
          # Support date in item so we can use stored test features
          todays_date = if item[:todaysDate].present?
            DateTime.parse(item[:todaysDate])
          else
            DateTime.now
          end

          status_date = DateTime.parse(item[:statusDate])
          diff = status_date - todays_date
          # we have to accommodate dates in the past and the future relative to today
          # remove times from past dates over 1 day old and future dates more than 2 days away
          if diff.to_i > 2 || diff.to_i < 0
            datetime = item[:statusDate].gsub(/\s.+/, '')
          else
            datetime = item[:statusDate]
          end
        end

        datetime

      end

      def make_substitutions(message, item)

        # substitute values for tokens in message strings

        # date
        datetime = format_datetime(item)
        message = message.gsub('%DATE', datetime || '')

        # number of requests
        if item[:requestCount] && item[:requestCount] > 0
          message = message.gsub('%REQS', item[:requestCount].to_s)
        end
        # hold location
        if item[:holdLocation].present?
          message = message.gsub('%LOC', item[:holdLocation])
        end

        message

      end

      def add_label(message, item)
        # label is descriptive information for items; optional

        # labels = []
        # [:enumeration, :chronology, :year, :caption, :text].each do |type|
        #   labels << item[type] if item[type]
        # end
        # labels.empty? ? label = '' : label = labels.join(' ') + ' '
        
        label = item[:itemLabel] || ''
        if label.empty?
          message
        else
          "#{label} #{message}"
        end

        # # add label
        # message.insert(0, "#{label} ") unless label.empty?
        # 
        # message
      end

    end
  end
end