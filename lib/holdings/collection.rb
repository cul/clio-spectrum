module Voyager
  module Holdings
    class Collection
      attr_reader :records


      # Documents may look different depending on who you are.  Pass in current_user.
      def initialize(document, circ_status, current_user=nil)
        raise "Voyager::Holdings::Collection got nil/empty document" unless document
        # raise "Voyager::Holdings::Collection got nil/empty circ_status" unless circ_status

        @current_user = current_user

        circ_status ||= {}
        document_status = circ_status[document.id] || {}
        document_marc = document.to_marc

        # collect mfhd records
        @records = []
        document_marc.each_by_tag('852') do |t852|
          # Sequence - MFHD ID used to gather all associated fields
          mfhd_id = t852['0']
          mfhd_status = document_status[mfhd_id] || {}
          # Rails.logger.debug "parse_marc:  mfhd_id=[#{mfhd_id}]"
          @records << Record.new(mfhd_id, document_marc, mfhd_status, @current_user)
        end

        adjust_services(@records) if @records.length > 1

      end

      # Generate output holdings data structure from array of Record objects
      def to_holdings()

        output = {}

        holdings = @records.collect { |rec| rec.to_hash }
# raise
        output[:condensed_holdings_full] = condense_holdings(holdings)

        output.with_indifferent_access
      end


      private


      # For records with multiple holdings, based on the overall content, adjust as follows:
      # -- remove document delivery options if there is an available offsite copy
      # -- remove borrowdirect and ill options if there is an available non-reserve, circulating copy
      def adjust_services(records)

        # set flags
        offsite_copy = "N"
        available_copy = "N"
        records.each do |record|
          offsite_copy = "Y" if record.services.include?('offsite')
          if record.item_status[:status] == 'available'
            available_copy = "Y" unless record.location_name.match(/Reserve|Non\-Circ/)
          end
        end

        # adjust services
        records.each do |record|
          record.services.delete('doc_delivery') if offsite_copy == "Y"
          record.services.delete('borrow_direct') if available_copy == "Y"
          record.services.delete('ill') if available_copy == "Y"
        end

      end

      def condense_holdings(holdings)
        # processing varies depending on complexity
        complexity = determine_complexity(holdings)
        entries = process_holdings(holdings, complexity)
        return entries
      end

      def determine_complexity(holdings)
        # holdings are complex if anything other than item_status has a value
        complexity = :simple
      
        holdings.each do |holding|
          if [:summary_holdings, :supplements, :indexes, :public_notes,
              :reproduction_note, :current_issues,
              :temp_locations,
              :orders,
              :donor_info, :urls].any? { |key| holding[key].present?}
            complexity = :complex
          end
        end
      
        complexity
      end

      def process_holdings(holdings, complexity)
        entries = []

        # Look at each Holding in turn...
        holdings.each do |holding|

          # Do we already have an entry for this holding-location and holding-call-number?
          entry = entries.find { |this_entry| 
            this_entry[:location_name] == holding[:location_name] &&
              this_entry[:call_number] == holding[:call_number] 
          }

          # If we're seeing this location/call-num for the first time, initialize an 'entry'
          unless entry
            entry = {
              :location_name => holding[:location_name],
              :location_note => holding[:location_note],
              :call_number => holding[:call_number],
              :status => '',
              :holding_id => [],
              :copies => [],
              :services => []
            }
            entry[:copies] << { :items => {} } if complexity == :simple
            entries << entry
          end

          # add holding_id
          entry[:holding_id] << holding[:holding_id]

          # for simple holdings put consolidated status information in the first copy
          if complexity == :simple
            item_status = holding[:item_status]
            messages    = item_status[:messages]
            # loop over "messages", that is, item-status-data-structures
            messages.each do |message|
              text = message[:short_message]
              if entry[:copies].first[:items].has_key?(text)
                entry[:copies].first[:items][text][:count] += 1
              else
                entry[:copies].first[:items][text] = {
                  :status => item_status[:status],
                  :count => 1
                }
              end
            end
          # for complex holdings create hash of elements for each copy and add to entry :copies array
          else
            out = {}
            # process status messages
            item_status = holding[:item_status]
            messages = item_status[:messages]
            out[:items] = {}
            messages.each do |message|
              if out[:items].has_key?(text)
                out[:items][text][:count] += 1
              text = message[:short_message]
              else
                copy[:items][text] = { status: item_status[:status], count: 1 }
              end
            end

            # add other elements to :copies array
            [ :current_issues, :donor_info, :indexes, :public_notes, :orders, 
              :reproduction_note, :supplements, :summary_holdings, 
              :temp_locations, :urls ].each { |element|
              add_holdings_elements(copy, holding, element)
            }

            entry[:copies] << out
          end
          end # end complexity == :complex

          entry[:services] << holding[:services]
        end

        # Now that multiple same-location holdings have been merged into entries,
        # rationalize some of the entry fields

        # get overall status of each location entry
        entries.each { |entry|
          entry[:status] = determine_overall_status(entry)
        }

        # condense services list
        entries.each { |entry|
          entry[:services] = entry[:services].flatten.uniq
        }
        
        # output_condensed_holdings(entries, options[:content_type])
        return entries
      end


      def add_holdings_elements(out, holding, type)
        case type
        when :current_issues
          out[type] = "Current Issues: " + holding[type].join(' -- ') unless holding[type].empty?
        when :donor_info
          unless holding[type].empty?
            # for text display as note
            messages = holding[type].each.collect { |info| info[:message] }
            out[type] = "Donor: " + messages.uniq.join(' -- ')
            # for display in conjunction with the Gift icon
            # this is set up to dedup but so far there have only been single donor info entries per holding
            out[:donor_info_icon] = []
            message_list = []
            holding[type].each do |info|
              unless message_list.include?(info[:message_brief])
                out[:donor_info_icon] << { :message => info[:message_brief], :url => info[:url] }
                message_list << info[:message_brief]
              end
            end
          end
        when :indexes
          out[type] = "Indexes: " + holding[type].join(' -- ') unless holding[type].empty?
        when :public_notes
          out[type] = "Notes: " + holding[type].join(' -- ') unless holding[type].empty?
        when :orders
          out[type] = "Order Information: " + holding[type].join(' -- ') unless holding[type].empty?
        when :reproduction_note
          out[type] = holding[type] unless holding[type].empty?
        when :supplements
          out[type] = "Supplements: " + holding[type].join(' -- ') unless holding[type].empty?
        when :summary_holdings
          out[type] = "Library has: " + holding[type].join(' -- ') unless holding[type].empty?
        when :temp_locations
          out[type] = holding[type] unless holding[type].empty?
        when :urls
          out[type] = holding[type] unless holding[type].empty?
        else
        end

      end

      def determine_overall_status(entry)

        a = 0   # available
        s = 0   # some available
        n = 0   # not available

        status = ''

        entry[:copies].each do |copy|
          copy[:items].each_pair do |message,details|
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
        #

        case a + s + n
        when 0
          status = 'none'
          status = 'online' if entry[:location_name].match(/^Online/)
        when 1
          status = 'available'
        when 4
          status = 'not_available'
        else
          status = 'some_available'
        end

        return status
      end

    end
  end
end
