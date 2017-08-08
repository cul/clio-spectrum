module Voyager
  module Holdings
    class Order
      attr_reader :orders, :current_issues

      # Order class initializing method
      # Populates instance variables from the mfhd:mfhdRecord node.
      #
      # * *Args*    :
      #   - +xml_node+ -> mfhd:mfhdRecord node
      #
      def initialize(marc)

        # serials checkIn node
        @current_issues = parse_current_issues(marc)

        # purchase order line items node
        @orders = parse_orders(marc)
      end

      private

      # Parses the mfhd:serialsCheckIn node and creates an array of curent issues
      #
      # * *Args*    :
      #   - +serialsCheckIn+ -> mfhd:serialsCheckIn node
      # * *Returns* :
      #   - Array of messages for current issues
      #   - An empty array if there is no mfhd:serialsCheckIn node
      #
      def parse_current_issues(marc)
        return [] unless marc

        current_issues = []
        marc.each_by_tag('895') do |t895|
          current_issues << t895['a']
        end

        current_issues
      end

      # Parses the mfhd:poLineItems node and creates an array of order messages
      #
      # * *Args*    :
      #   - +poLineItems+ -> mfhd:poLineItems node
      # * *Returns* :
      #   - Array of message hashes for orders
      #       :status_code => status code
      #       :short_message => short version of the message
      #       :long_message => long version of the message
      #   - An empty array if there is no mfhd:poLineItems node
      #
      def parse_orders(marc)
        return [] unless marc

        orders = []
        marc.each_by_tag('894') do |t894|
          orders << t894['a']
        end

        orders

        # # generates and returns an array of order messages
        # poLineItems.css("mfhd|lineItemStatus").collect { |lineItemStatus| generate_order_message(lineItemStatus) }
      end

      # # Generate an order message from an mfhd:lineItemStatus node
      # #
      # # * *Args*    :
      # #   - +lineItemStatus+ -> an mfhd:lineItemStatus node
      # # * *Returns* :
      # #   - An order message
      # #
      # def generate_order_message(lineItemStatus)
      # 
      #   status = lineItemStatus.at_css("mfhd|status").content
      #   date = lineItemStatus.at_css("mfhd|date").content
      # 
      #   # get parms for the message being processed
      #   parms = ORDER_STATUS_CODES[status]
      # 
      #   raise "Status code not found in config/order_status_codes.yml" unless parms
      # 
      #   short_message = parms['short_message'].gsub('%DATE',date)
      #   long_message = parms['long_message'].gsub('%DATE',date)
      # 
      #   { :status_code => status, :short_message => short_message, :long_message => long_message }
      # 
      # end

    end

  end

end
