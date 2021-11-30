module Holdings
  class Collection
    attr_reader :records

    def initialize(document, circ_status, scsb_status)
      raise 'Holdings::Collection got nil/empty document' unless document
      # raise "Holdings::Collection got nil/empty circ_status" unless circ_status

      circ_status ||= {}
      scsb_status ||= {}
      document_status = circ_status[document.id] || {}
      document_marc = document.to_marc

      # collect mfhd records
      @holdings_records = []
      document_marc.each_by_tag('852') do |t852|
        # Sequence - MFHD ID used to gather all associated fields
        mfhd_id = t852['0']
        mfhd_status = document_status[mfhd_id] || {}
        # Rails.logger.debug "parse_marc:  mfhd_id=[#{mfhd_id}]"
        @holdings_records << Record.new(mfhd_id, document_marc, mfhd_status, scsb_status)
      end

      # Looking over all holdings copies may affect offered services
      adjust_services_across_holdings(document, @holdings_records) if @holdings_records.length > 1

      # Some qualities of the bib record affect services offered on the holdings records
      adjust_services_for_bib(document, @holdings_records)
    end

    # Generate output holdings data structure from array of Record objects
    def to_holdings
      output = {}

      holdings = @holdings_records.collect(&:to_hash)
      # raise

      # The SCSB MARC sometimes puts each item of an NYPL serial in it's own
      # holdings record (results in 100's of holdings records)
      # These holdings records can be consolidated for the CLIO display.
      if holdings.first[:location_name] =~ /NYPL/
        holdings = consolidate_nypl_holdings(holdings)
      end

      output[:condensed_holdings_full] = condense_holdings(holdings)
      output.with_indifferent_access
    end

    private

    # This only consolidates duplicates into the first holding.
    # It doesn't, e.g., consolidate holdings 4 with 6, if they match.
    # We can build that if we find we need to.
    def consolidate_nypl_holdings(original_holdings)
      return [] unless original_holdings.present?

      # Below logic only for NYPL
      return original_holdings unless original_holdings.first[:location_name] =~ /NYPL/

      holdings = []
      first = original_holdings.shift
      holdings << first
      original_holdings.each do |holding|
        # If this holding matches the first, consolidate
        if nypl_holding_match(first, holding)
          first[:item_count] = first[:item_count] + holding[:item_count]
        else
          holdings << holding
        end
      end
      holdings
    end

    # Are these two holdings really just two items within
    # the same holding?
    def nypl_holding_match(a, b)
      return false unless a.present? && b.present?

      # These fields should be non-blank, and equal between holdings
      [:bibid, :location_name, :call_number].each do |key|
        return false unless a[key].present? && b[key].present?
        return false if a[key] != b[key]
      end

      # These other fields may or may not be blank, but must match
      [:supplements, :indexes, :public_notes, :reproduction_note,
       :current_issues, :temp_locations, :use_restrictions, :bound_withs,
       :orders, :donor_info, :urls, :summary_holdings,
       :shelving_title, :location_note].each do |key|
        return false if a[key] != b[key]
      end

      true
    end

    # Some qualities of the bib record affect services offered
    def adjust_services_for_bib(document, holdings_records)

      # NEXT-1673 - only offer "Scan" for certain formats
      scan_formats = APP_CONFIG['scan_formats'] || ['book']
      # If there's no intersection between this bib's formats and the scannable list,
      # Then remove all scan-related service links
      if (document['format'] & scan_formats).empty?
        holdings_records.each do |record|
          record.services.delete('ill_scan')
          record.services.delete('recap_scan')
        end
      end

    end

    # For records with multiple holdings, based on the overall content, adjust as follows:
    # -- remove document delivery options if there is an available offsite copy
    # -- remove borrowdirect and ill options if there is an available non-reserve, circulating copy
    def adjust_services_across_holdings(document, holdings_records)
      # set flags
      offsite_copy = 'N'
      available_copy = 'N'
      holdings_records.each do |record|
        offsite_copy = 'Y' if record.services.include?('offsite')
        if record.item_status[:status] == 'available'
          available_copy = 'Y' unless record.location_name =~ /Reserve|Non\-Circ/ || record.location_name =~ /BearStor/
        end
      end
      
      # If there's ANY copy available on-campus for scanning,
      # we'll remove any links to ILL Scan services
      campus_scan_available = holdings_records.any? do |record|
        record.services.include?('campus_scan')
      end
      holdings_records.each do |record|
        # NEXT-1739 - Campus Scan should NOT block ReCAP Scan any longer
        # record.services.delete('recap_scan') if campus_scan_available
        record.services.delete('ill_scan') if campus_scan_available
      end

      # If there's ANY copy available for Pickup, don't offer Borrow Direct
      pickup_available = holdings_records.any? do |record|
        record.services.include?('campus_paging') ||
        record.services.include?('recap_loan')
      end
      holdings_records.each do |record|
        record.services.delete('borrow_direct') if pickup_available
      end
      
      holdings_records.each do |record|
        # LIBSYS-4423 - For serials, different holdings may offer different issues,
        # don't suppress parallel pickup options
        unless document['format'].any? { |format| format.match?(/journal/i) }
          # NEXT-1559 - don't display bearstor request link if copy is available
          record.services.delete('barnard_remote') if available_copy == 'Y'
        end
      end

    end


    def determine_complexity(holdings)
      # holdings are complex if anything other than item_status has a value

      holdings.each do |holding|
        # If any of these fields are filled in for any holding, then this
        # is a complex record.
        if [:summary_holdings, :supplements, :indexes, :public_notes,
            :reproduction_note, :current_issues,
            :temp_locations, :use_restrictions, :bound_withs,
            :orders,
            :donor_info, :urls].any? { |key| holding[key].present? }
          return :complex
        end
      end

      # We didn't find anything complex, these holdings are simple.
      :simple
    end


    # def condense_holdings(holdings)
    #   # processing varies depending on complexity
    #   complexity = determine_complexity(holdings)
    #   entries = process_holdings(holdings, complexity)
    #   entries
    # end

    # def process_holdings(holdings, complexity)
    def condense_holdings(holdings)
      # processing varies depending on complexity
      complexity = determine_complexity(holdings)

      entries = []

      # Look at each Holding in turn...
      holdings.each do |holding|
        # Do we already have an entry for this holding-location and holding-call-number?
        entry = entries.find do |this_entry|
          this_entry[:location_name] == holding[:location_name] &&
            this_entry[:call_number] == holding[:call_number]
        end

        # If we're seeing this location/call-num for the first time, initialize an 'entry'
        unless entry
          entry = {
            location_name: holding[:location_name],
            location_code: holding[:location_code],
            location_note: holding[:location_note],
            call_number: holding[:call_number],
            status: '',
            holding_id: [],
            copies: [],
            services: []
          }
          entry[:copies] << { items: {} } if complexity == :simple
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

            # If an item is 'Available', but marked as 'some_available',
            # then it can be omitted from display,
            # since there'll be some kind of more interesting unavailable item.

            # Group items by "text", i.e., by string status label.

            # If we're seeing this text for the first time, it's a new item
            if !entry[:copies].first[:items].key?(text)
              entry[:copies].first[:items][text] = {
                status: item_status[:status],
                count: 1,
                copy_count: 1,
                mfhd_id_list: [holding[:holding_id]]
              }

            # Otherwise, if we're seeing this text another time...
            else
              # Is this item another same-status item from the same holding?
              # If so, then just bump up the item (volume, part, etc.) count.
              mfhd_id_list = entry[:copies].first[:items][text][:mfhd_id_list]
              if mfhd_id_list.include?(holding[:holding_id])
                entry[:copies].first[:items][text][:count] += 1

              # Otherwise, if it's from a different holding, then it's a new copy
              else
                entry[:copies].first[:items][text][:copy_count] += 1
                entry[:copies].first[:items][text][:mfhd_id_list].push holding[:holding_id]
              end

            end
          end
        # for complex holdings create hash of elements for each copy and add to entry :copies array
        else
          copy = { items: {} }

          # process status messages
          item_status = holding[:item_status]
          messages = item_status[:messages]
          messages.each do |message|
            text = message[:short_message]

            # If an item is 'Available', but marked as 'some_available',
            # then it can be omitted from display,
            # since there'll be some kind of more interesting unavailable item.
            # ### next if text == 'Available'
            next if item_status[:status] == 'some_available' && text == 'Available'
            # raise

            # If we're seeing this text for the first time, it's a new item
            if !copy[:items].key?(text)
              copy[:items][text] = {
                status: item_status[:status],
                count: 1,
                copy_count: 1,
                mfhd_id_list: [holding[:holding_id]]
              }

            # Otherwise, if we're seeing this text another time...
            else
              # Is this item another same-status item from the same holding?
              # If so, then just bump up the item (volume, part, etc.) count.
              mfhd_id_list = copy[:items][text][:mfhd_id_list]
              if mfhd_id_list.include?(holding[:holding_id])
                copy[:items][text][:count] += 1

                # Otherwise, if it's from a different holding, then it's a new copy
              else
                copy[:items][text][:copy_count] += 1
                copy[:items][text][:mfhd_id_list].push holding[:holding_id]
              end
              # Is
            end

            # # -- conflates copies with volumes --
            # if copy[:items].has_key?(text)
            #   copy[:items][text][:count] += 1
            # else
            #   copy[:items][text] = { status: item_status[:status], count: 1 }
            # end
          end

          # add other elements to :copies array
          [:current_issues, :donor_info, :indexes, :public_notes, :orders,
           :reproduction_note, :supplements, :summary_holdings,
           :temp_locations, :use_restrictions, :bound_withs, :urls].each do |element|
            add_holdings_elements(copy, holding, element)
          end

          entry[:copies] << copy
        end # end complexity == :complex

        entry[:services] << holding[:services]
      end

      # Now that multiple same-location holdings have been merged into entries,
      # rationalize some of the entry fields

      # get overall status of each location entry
      entries.each do |entry|
        entry[:status] = determine_overall_status(entry)
      end

      # condense services list
      entries.each do |entry|
        entry[:services] = entry[:services].flatten.uniq
      end

      # output_condensed_holdings(entries, options[:content_type])
      entries
    end

    def add_holdings_elements(out, holding, type)
      case type
      when :current_issues
        out[type] = 'Current Issues: ' + holding[type].join('<br>') unless holding[type].empty?
      when :donor_info
        unless holding[type].empty?
          # for text display as note
          messages = holding[type].each.collect { |info| info[:message] }
          out[type] = 'Donor: ' + messages.uniq.join('<br>')
          # for display in conjunction with the Gift icon
          # this is set up to dedup but so far there have only been single donor info entries per holding
          out[:donor_info_icon] = []
          message_list = []
          holding[type].each do |info|
            unless message_list.include?(info[:message_brief])
              out[:donor_info_icon] << { message: info[:message_brief], url: info[:url] }
              message_list << info[:message_brief]
            end
          end
        end
      when :indexes
        out[type] = 'Indexes: ' + holding[type].join('<br>') unless holding[type].empty?
      when :public_notes
        out[type] = 'Notes: ' + holding[type].join('<br>') unless holding[type].empty?
      when :orders
        out[type] = 'Order Information: ' + holding[type].join('<br>') unless holding[type].empty?
      when :reproduction_note
        out[type] = holding[type] unless holding[type].empty?
      when :supplements
        out[type] = 'Supplements: ' + holding[type].join('<br>') unless holding[type].empty?
      when :summary_holdings
        out[type] = 'Library has: ' + holding[type].join('<br>') unless holding[type].empty?
      when :temp_locations
        out[type] = holding[type] unless holding[type].empty?
      when :use_restrictions
        out[type] = holding[type] unless holding[type].empty?
      when :bound_withs
        out[type] = holding[type] unless holding[type].empty?
      when :urls
        out[type] = holding[type] unless holding[type].empty?
      end
    end

    def determine_overall_status(entry)
      a = 0   # available
      s = 0   # some available
      n = 0   # not available

      status = ''

      entry[:copies].each do |copy|
        copy[:items].each_pair do |_message, details|
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
        status = 'online' if entry[:location_name] =~ /^Online/
      when 1
        status = 'available'
      when 4
        status = 'not_available'
      else
        status = 'some_available'
      end

      status
    end
  end
end

