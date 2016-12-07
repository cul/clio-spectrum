module Voyager
  module Holdings
    class Item
      attr_reader :holding_id, :item_count, :temp_locations, :item_status

      # # Item class initializing method
      # # Populates instance variables from the mfhd:mfhdRecord node.
      # #
      # # * *Args*    :
      # #   - +xml_node+ -> mfhd:mfhdRecord node
      # #
      # def initialize(xml_node,location)
      def initialize(mfhd_id, marc)

        # @holding_id = xml_node.attributes["mfhdId"].value
        @holding_id = mfhd_id

        # # the item collecction
        # item = xml_node.at_css("mfhd|itemCollection")

        items = []
        marc.each_by_tag('876') do |t876|
          items << t876
        end

        # items = Array(marc['876']).select do |t876|
        #   t876['0'] == mfhd_id
        # end

        # number of item records
        # @item_count = item.at_css("item|itemCount").content
        @item_count = items.size

        # TODO
        # @temp_locations = parse_for_temp_locations(item,location)  # array
        @item_status = parse_for_circ_status(items, @item_count)  # hash

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
      def parse_for_temp_locations(item,location)

        # item:itemLocation nodes
        # reject nodes that do not have the tmpLoc attribute set
        # itemLocation = item.css("item|itemLocation").reject { |loc| loc.at_css("item|itemLocationData[@name='tmpLoc']").content.empty? }
        # reject nodes that match the mfhd display location
        itemLocation = item.css("item|itemLocation").reject { |loc| loc.at_css("item|itemLocationData[@name='tempLocation']").content == location }

        return [] unless itemLocation.length > 0

        # messages = []
        tempLocations = []

        itemLocation.each do |loc|
          # label is descriptive information for items; optional
          itemDetails = []
          ['itemEnum', 'itemChron','itemYear', 'itemCaption', 'itemFreeText'].each do |type|
            loc_data = loc.at_css("item|itemLocationData[@name=#{type}]")
            itemDetails << loc_data.content unless loc_data.content.empty?
          end

          itemLabel = itemDetails.join(' ')
          tempLocation = loc.at_css("item|itemLocationData[@name='tempLocation']").content
          tempLocations << { itemLabel: itemLabel, tempLocation: tempLocation }

          # # generate message
          # if label.empty?
          #   messages << "Shelved in " + tempLocation
          # else
          #   messages << itemLabel + " Shelved in " + tempLocation
          # end
        end

        # messages
        tempLocations

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
      def parse_for_circ_status(items,item_count)

        # no items = no status available
        if item_count == "0"
          return {:status => 'none',
                  :messages => [ {:status_code => '0',
                                  :short_message => 'Status unknown',
                                  :long_message => 'No item status available'} ]
                }
        end

        # # item:itemRecord nodes
        # itemRecord = item.css("item|itemRecord")
        # 
        # # generate an arry of hashes for ease of handling
        # records = itemRecord.collect do |record|
        #   data = {}
        #   record.css("item|itemData").each do |rec|
        #     data[rec.attr("name").to_sym] = rec.content
        #   end
        #   data
        # end

        # determine overall status
        status = determine_status(items,item_count)
        # generate messages
        messages = generate_messages(items)

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
      def determine_status(records,item_count)

        # TODO
        return 'unknown'

        # # assume available
        # status = 'available'
        # unavailable = 0
        # # if statusCode > 1 some item status is set so some item may not be available; 11 (returned) is the exception
        # records.each { |record| unavailable += 1 if record[:statusCode].to_i > 1 && record[:statusCode].to_i != 11 }
        # unless unavailable == 0
        #   if unavailable == item_count.to_i
        #     status = 'not_available'
        #   else
        #     status = 'some_available'
        #   end
        # end
        # 
        # status

      end

      # Generate circulation messages
      #
      # * *Args*    :
      #   - +records+ -> Array of hashes for data in item:itemRecord nodes
      # * *Returns* :
      #   - Array of circulation messages
      #
      def generate_messages(items)

        messages = []
        items.each do |item|
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
      def generate_message(record)

        short_message = ''
        long_message = ''
        code = ''

        # TODO
        # # status patron message otherwise regular message
        # if record[:patronGroupCode].strip.match(/^(IND|MIS|ACO)/)
        #   code = 'sp'
        #   long_message = record[:lastName].strip + ' ' + record[:firstName].strip
        #   # done in two steps in case ending puctuation is missing
        #   short_message = long_message.gsub(/(Try|Place).+/, '').strip
        #   short_message = short_message.gsub(/\W$/, '')
        # 
        # else
        # 
        #   code = record[:statusCode]
        #   # append suffix to indicate whether there are requests - n = no requests, r = requests
        #   record[:requestCount] == '0' ? code += 'n' : code += 'r'
        # 
        #   # get parms for the message being processed
        #   parms = ITEM_STATUS_CODES[code]
        # 
        #   raise "Status code not found in config/item_status_codes.yml" unless parms
        # 
        #   short_message = make_substitutions(parms['short_message'],record)
        #   long_message = make_substitutions(parms['long_message'],record)
        # 
        # end
        # 
        # # add labels
        # short_message = add_label(short_message,record)
        # long_message = add_label(long_message,record)

        return { :status_code => code,
                  :short_message => short_message,
                  :long_message => long_message }

      end

      def format_datetime(record)

        # format date / time
        datetime = ''
        unless record[:statusDate].empty?
          # use date in record so we can use stored test features
          todays_date = DateTime.parse(record[:todaysDate])
#          todays_date = DateTime.now
          status_date = DateTime.parse(record[:statusDate])
          diff = status_date - todays_date
          # we have to accommodate dates in the past and the future relative to today
          # remove times from past dates over 1 day old and future dates more than 2 days away
          if diff.to_i > 2 || diff.to_i < 0
            datetime = record[:statusDate].gsub(/\s.+/, '')
          else
            datetime = record[:statusDate]
          end
        end

        datetime

      end

      def make_substitutions(message,record)

        datetime = format_datetime(record)

        # substitute values for tokens in message strings
        # date
        unless datetime.empty?
          message = message.gsub('%DATE', datetime)
        end
        # number of requests
        unless record[:requestCount] == '0'
          message = message.gsub('%REQS', record[:requestCount])
        end
        # hold location
        unless record[:holdLocation].empty?
          message = message.gsub('%LOC', record[:holdLocation])
        end

        message

      end

      def add_label(message,record)

        # label is descriptive information for items; optional
        labels = []
        [:enumeration, :chronology, :year, :caption, :text].each do |type|
          labels << record[type] unless record[type].empty?
        end
        labels.empty? ? label = '' : label = labels.join(' ') + ' '

        # add label
        message.insert(0, label) unless label.empty?

        message

      end

    end
  end
end