module Voyager
  module Holdings
    class Record
      attr_reader :holding_id, :location_name, :call_number,
                  :summary_holdings, :public_notes,
                  :shelving_title, :supplements, :indexes,
                  :reproduction_note, :urls, :item_count,
                  :temp_locations, :use_restrictions, :bound_withs,
                  :item_status, :orders, :current_issues, :services,
                  :bibid, :donor_info, :location_note, :temp_loc_flag

      def initialize(mfhd_id, marc, mfhd_status, scsb_status)
        mfhd_status ||= {}

        @bibid = marc['001'].value
        @holding_id = mfhd_id

        tag852 = nil
        marc.each_by_tag('852') do |this852|
          tag852 = this852 if this852['0'] == mfhd_id
        end

        tag866list = []
        marc.each_by_tag('866') do |this866|
          tag866list.push(this866) if this866['0'] == mfhd_id
        end

        tag890list = []
        marc.each_by_tag('890') do |this890|
          tag890list.push(this890) if this890['0'] == mfhd_id
        end

        @location_name = tag852['a'] || tag852['b']

        @location_code = tag852['b']

        # ReCAP partner records don't have an 852$a
        if @location_name =~ /^scsb/i
          @location_name = TrajectUtility.recap_location_code_to_label(@location_name)
        end

        @call_number      = parse_call_number(tag852)           # string
        @summary_holdings = parse_summary_holdings(tag866list)  # array
        @public_notes     = parse_public_notes(tag890list)      # array
        @shelving_title   = parse_shelving_title(tag852)        # string

        holdings_tags = %w(867 868
                           876
                           891 892 893 894 895)

        holdings_marc = MARC::Record.new
        marc.each_by_tag(holdings_tags) do |tag|
          holdings_marc.append(tag) if tag['0'] == mfhd_id
        end

        # 867$a
        @supplements = parse_supplements(holdings_marc) # array
        # 868$a
        @indexes = parse_indexes(holdings_marc) # array
        # 892
        @reproduction_note = parse_reproduction_note(holdings_marc) # string
        # 893
        @urls = parse_urls(holdings_marc) # array of hashes
        # 891
        @donor_info = parse_donor_info(holdings_marc) # array of hashes
        # 894$a
        @orders = parse_orders(holdings_marc)
        # 895$a
        @current_issues = parse_current_issues(holdings_marc)

        @location_note = assign_location_note(@location_code) # string

        # information from item level records
        item = Item.new(mfhd_id, holdings_marc, mfhd_status, scsb_status)

        @item_count = item.item_count

        @temp_locations = item.temp_locations
        @use_restrictions = item.use_restrictions
        @bound_withs = item.bound_withs
        @item_status = item.item_status

        # NEXT-1502 - display_helper.rb and record.rb
        # Sometimes libraries become Unavailable (moves, renovations).
        # Change OPAC display/services instead of updating ALL items in ILMS
        unavailable_locations = APP_CONFIG['unavailable_locations'] || []
        unavailable_name = unavailable_locations.select { |loc| @location_name.match(/^#{loc}/) }.first
        if unavailable_name.present?
          # Hardcode the full item status data-structure
          @item_status = { status: 'not_available', messages: [{ status_code: '14n', short_message: 'Unavailable' }] }
          all_notes = APP_CONFIG['unavailable_notes'] || []
          note = all_notes[unavailable_name]
          @location_note = note if note.present?
        end

        # East Asian Flood!
        # If the app-config key is set, we'll do some overrides
        if APP_CONFIG['east_asian_flood'].present? && @location_name.match(/^East Asian/)
          # Only do overrides for 'Available' items.
          # Unavailable (checked-out, in-process, etc.), display true Voyager status
          if @item_status[:status] == 'available'
            if soggy?
              # Soggy items have been checked out to a status patron,
              # so we'll just let the status-patron message display.
              # @item_status = {status: "not_available", messages: [{status_code: "98n", short_message: 'Temporarily unavailable. Try ILL'}]}
            else
              # Dry items should continue to direct patrons to staff paging
              @item_status[:messages].each do |m|
                m[:short_message] = 'Please contact Starr East Asian Library staff for assistance in paging this item.'
              end
            end
          end
        end

        # LIBSYS-2219 - Lehman Mold Bloom!
        # If the app-config key is set, do some overrides to display of item status
        if APP_CONFIG['lehman_mold'].present? && @location_name.match(/^Lehman/)
          # Only do overrides for 'Available' items.
          # Unavailable (checked-out, in-process, etc.), display true Voyager status
          if @item_status[:status] == 'available'
            if moldy?
              # NO Voyager changes have been done in this case.
              # Override the full @item_status in CLIO code
              @item_status = {
                status: 'not_available', 
                messages: [
                  {
                    status_code:   'sp', 
                    short_message: 'Temporarily unavailable. Try Borrow Direct or ILL',
                    long_message:  'Temporarily unavailable. Try Borrow Direct or ILL'
                  }
                ]
              }
            end
          end
        end


        # flag for services processing (doc_delivery assignment)
        # NEXT-1234: revised logic
        @temp_loc_flag = 'N'
        unless @temp_locations.empty?

          # if all items have temp locations we can't determine doc delivery status (no location codes available in item information)
          @temp_loc_flag = 'Y' if @temp_locations.length == @item_count
          # special case for single temp location
          if @item_count == 1
            # # temp location begins 'Shelved in' if it is not for a part
            # if @temp_locations.first.match(/^Shelved/)
            #   # remove 'Shelved in' and replace location_name with temp location
            #   @location_name = @temp_locations.first.gsub(/^Shelved in /, '')
            #   @temp_locations.clear
            # end
            # itemLabel will be empty if it is not for a part
            if @temp_locations.first[:itemLabel].blank?
              # replace location_name with temp location, clear temp location
              @location_name = @temp_locations.first[:tempLocation]
              @temp_locations.clear
            end
          end
        end

        # set item status for online items
        if @location_name =~ /^Online/
          @item_status[:status] = 'online'
          @item_status[:messages].clear
        end

        # get format codes from leader
        fmt = marc.leader[6..7]

        # add available services
        @services = determine_services(@location_name, @location_code, @temp_loc_flag, @call_number, @item_status, @orders, @bibid, fmt)
      end

      # Collect data from all variables into a hash
      def to_hash
        {
          bibid: @bibid,
          holding_id: @holding_id,
          location_name: @location_name,
          location_code: @location_code,
          location_note: @location_note,
          call_number: @call_number,
          shelving_title: @shelving_title,
          summary_holdings: @summary_holdings,
          supplements: @supplements,
          indexes: @indexes,
          public_notes: @public_notes,
          reproduction_note: @reproduction_note,
          urls: @urls,
          donor_info: @donor_info,
          item_count: @item_count,
          temp_locations: @temp_locations,
          use_restrictions: @use_restrictions,
          bound_withs: @bound_withs,
          item_status: @item_status,
          services: @services,
          current_issues: @current_issues,
          orders: @orders
        }
      end

      private

      # Extract call number
      #
      # * *Args*    :
      #   - +tag852+ -> 852 field node; not repeatable
      # * *Returns* :
      #   - Call number string
      #
      def parse_call_number(tag852)
        g = tag852.subfields.collect { |s| s.value if s.code == 'g' }
        h = tag852.subfields.collect { |s| s.value if s.code == 'h' }
        i = tag852.subfields.collect { |s| s.value if s.code == 'i' }
        k = tag852.subfields.collect { |s| s.value if s.code == 'k' }
        m = tag852.subfields.collect { |s| s.value if s.code == 'm' }

        # subfields need to be output in this order even though they may not appear in this order
        call_number = [k, g, h, i, m].flatten.join(' ').strip

        # NEXT-1416 - Suppress "no call number" message
        return '' if call_number =~ /no.*call.*num/i

        call_number
      end

      # Extract summary holdings from 866 field
      #
      # * *Args*    :
      #   - +tag866list+ -> Array of 866 field nodes,
      # * *Returns* :
      #   - Array of summary holdings statements
      #   - Empty array if there are no summary holdings
      #
      def parse_summary_holdings(tag866list)
        return [] unless tag866list && !tag866list.empty?

        summary = tag866list.collect do |tag866|
          tag866.subfields.select { |s| s.code == 'a'  && !s.value.empty? }.collect(&:value)
        end.flatten
      end

      def parse_public_notes(tag890list)
        return [] unless tag890list && !tag890list.empty?

        public_notes = tag890list.collect do |tag890|
          tag890.subfields.select { |s| s.code == 'a'  && !s.value.empty? }.collect(&:value)
        end.flatten
      end

      # # Extract public notes from 852 field, subfield z
      # #
      # # * *Args*    :
      # #   - +tag852+ -> 852 field node; not repeatable
      # # * *Returns* :
      # #   - Array of note statements
      # #   - Empty array if there are no notes
      # #
      # def parse_notes_852(tag852)
      #   return [] unless tag852 && tag852['z']
      #
      #   notes = tag852.subfields.collect {|s| s.value if s.code == 'z'}
      #   notes.compact.collect { |subfield| subfield.strip }
      #
      #   # subz = tag852.css("slim|subfield[@code='z']")
      #   # # there can be multiple z's
      #   # subz.collect { |subfield| subfield.content }
      # end
      #
      # # Extract public notes from 866 fields, subfield z
      # #
      # # * *Args*    :
      # #   - +tag866+ -> 866 field node; repeatable
      # # * *Returns* :
      # #   - Array of note statements
      # #   - Empty array if there are no notes
      # #
      # def parse_notes_866(tag866list)
      #   return [] unless tag866list && tag866list.size > 0
      #
      #   summary = tag866list.collect { |tag866|
      #     tag866.subfields.select {|s| s.code == 'z'  && ! s.value.empty?}.collect{|s| s.value }
      #   }.flatten
      #
      #   # return [] unless tag866 && tag866['z']
      #   #
      #   # notes = tag866.subfields.collect {|s| s.value if s.code == 'z'}
      #   # notes.compact.collect { |subfield| subfield.strip }
      #
      #   # return [] unless tag866
      #   #
      #   # notes = tag866.collect do |field|
      #   #   field.at_css("slim|subfield[@code='z']")
      #   # end
      #   #
      #   # notes.compact.collect { |subfield| subfield.content }
      #
      # end

      # Extract shelving title
      #
      # * *Args*    :
      #   - +tag852+ -> 852 field node; not repeatable
      # * *Returns* :
      #   - Shelving title string
      #
      def parse_shelving_title(tag852)
        return '' unless tag852 && tag852['l']

        tag852['l'].strip
      end

      # Extract supplement holdings from field 867
      #
      # * *Args*    :
      #   - +marc+ -> mfhd:marcRecord node
      # * *Returns* :
      #   - Array of supplement holdings statements
      #   - Empty array if there are no summary holdings
      #
      def parse_supplements(marc)
        tag867 = marc['867']
        return [] unless tag867

        supplements = []

        marc.each_by_tag('867') do |t867|
          supplements.push(t867.subfields.collect { |s| s.value if %w(a z).include? s.code }.join(' ').strip)
        end

        supplements
      end

      # Extract index holdings from field 868
      #
      # * *Args*    :
      #   - +marc+ -> mfhd:marcRecord node
      # * *Returns* :
      #   - Array of index holdings statements
      #   - Empty array if there are no summary holdings
      #
      def parse_indexes(marc)
        tag868 = marc['868']
        return [] unless tag868

        indexes = []

        marc.each_by_tag('868') do |t868|
          indexes.push(t868.subfields.collect { |s| s.value if s.code == 'a' }.join(' ').strip)
        end

        indexes
      end

      # Extract reproduction note from field 843
      #
      # * *Args*    :
      #   - +marc+ -> mfhd:marcRecord node
      # * *Returns* :
      #   - Reproduction note string
      #
      def parse_reproduction_note(marc)
        tag892 = marc['892']
        return '' unless tag892

        # collect subfields in input order; only ouput certain subfields
        tag892.subfields.collect { |s| s.value if 'abcdefmn3'.include? s.code }.join(' ').strip
      end

      # Extract URLs from 856 fields in the marc holdings record
      #
      # * *Args*    :
      #   - +marc+ -> mfhd:marcRecord node
      # * *Returns* :
      #   - Array of hashes for urls
      #     { :url => url, :link_text => link text }
      #   - Empty array if there are no urls in the holdings record
      # Note: there may be urls in the bib record.
      #
      def parse_urls(marc)
        tag893 = marc['893']
        return [] unless tag893

        urls = []

        marc.each_by_tag('893') do |t893|
          ind1 = t893.indicator1
          ind2 = t893.indicator2

          subu = t893['u']
          subz = t893['z']
          sub3 = t893['3']

          next unless subu
          url = subu
          # link_text = [sub3, subz].compact.collect { |subfield| subfield.value }.join(' ')
          link_text = [sub3, subz].compact.join(' ')
          link_text = url if link_text.empty?
          urls << { ind1: ind1, ind2: ind2, url: url, link_text: link_text }
        end

        urls
      end

      # Extract donor note & code from field 541
      #
      # * *Args*    :
      #   - +marc+ -> mfhd:marcRecord node
      # * *Returns* :
      #   - Array of hashes for donor information
      #     { :message => message, :code => code }
      #   - Empty array if there are no donor notes
      #
      def parse_donor_info(marc)
        tag891 = marc['891']
        return [] unless tag891

        donor_info = []
        marc.each_by_tag('891') do |t891|
          next unless t891.indicator1 == '1'

          # collect subfields in input order; only ouput certain subfields
          # do not include subfield c and 3 in brief message (use with gift icon)
          message = t891.subfields.collect { |s| s.value if 'acd3'.include? s.code }.compact.join(' ').strip
          message_brief = t891.subfields.collect { |s| s.value if 'ad'.include? s.code }.compact.join(' ').strip
          sube = t891['e']
          code = ''
          code = sube.strip if sube
          # get the name coded after 'plate:'
          name = ''
          name = Regexp.last_match(1).strip if code.downcase =~ /^plate:(.+)/
          # use name to see if there is a url to a donor page or a special text
          url = ''
          unless name.empty?
            entry = DONOR_INFO[name]
            unless entry.nil?
              url = entry['url']
              message_brief = entry['txt'] unless entry['txt'].empty?
            end
          end
          donor_info << { message: message, message_brief: message_brief, code: code, url: url }
        end

        donor_info
      end

      def parse_current_issues(marc)
        return [] unless marc

        current_issues = []
        marc.each_by_tag('895') do |t895|
          current_issues << t895['a']
        end

        current_issues
      end

      def parse_orders(marc)
        return [] unless marc

        orders = []
        marc.each_by_tag('894') do |t894|
          orders << t894['a']
        end

        orders
      end

      def assign_location_note(location_code)
        location_note = ''

        # Avery Art Properties (NEXT-1318)
        if location_code == 'avap'
          location_note = 'By appointment only. See the <a href="https://library.columbia.edu/locations/avery/art-properties.html" target="_blank">Avery Art Properties webpage</a>'
          return location_note
        end

        # Avery Classics
        if ['avr', 'avr,cage', 'avr,rrm', 'avr,stor', 'far', 'far,cage', 'far,rrm',
            'far,stor', 'off,avr', 'off,far'].include?(location_code)
          location_note = 'By appointment only. See the <a href="https://library.columbia.edu/locations/avery/classics.html" target="_blank">Avery Classics Collection webpage</a>'
          return location_note
        end

        # Avery Drawings & Archives (NEXT-1318)
        if ['avda', 'ava', 'off,avda'].include?(location_code)
          location_note = 'By appointment only. See the <a href="https://library.columbia.edu/locations/avery/da.html" target="_blank">Avery Drawings & Archives webpage</a>'
          return location_note
        end

        # Barnard Archives
        if ['bar,bda', 'bar,spec', 'bara'].include?(location_code)
          location_note = 'Available by appointment. <a href="https://archives.barnard.edu/about-us/contact-us">Contact Barnard Archives.</a>'
          return location_note
        end

        # Burke
        if ['uts,arc', 'uts,essxx1', 'uts,essxx2', 'uts,essxx3', 'uts,gil', 'uts,mac',
            'uts,macxfp', 'uts,macxxf', 'uts,macxxp', 'uts,map', 'uts,mrldr', 'uts,mrldxf',
            'uts,mrlor', 'uts,mrloxf', 'uts,mrls', 'uts,mrlxxp', 'uts,mss', 'uts,perr',
            'uts,perrxf', 'uts,reled', 'uts,tms', 'uts,twr', 'uts,twrxxf',
            'uts,unnr', 'uts,unnrxf', 'uts,unnrxp'].include?(location_code)
          location_note = 'By appointment only. See the <a href="https://library.columbia.edu/locations/burke/using-special-collections.html" target="_blank">Burke Library special collections page</a>'
          return location_note
        end

        # LIBSYS-1365 - Geology Library closure
        unless APP_CONFIG['geology_not_yet'].present?
          if ['glg', 'glg,fol'].include?(location_code)
            location_note = "Geology collection: to request this item <em><a href='https://library.columbia.edu/find/request/geology-collection-paging/form.html'>click here</a></em>"
            return location_note
          end
        end

        location_note
      end

      def determine_services(location_name, location_code, temp_loc_flag, call_number, item_status, orders, bibid, fmt)
        services = []

        # ====== SPECIAL COLLECTIONS ======
        # NEXT-1229 - make this the first test
        # special collections request service [only service available for items from these locations]
        # LIBSYS-2505 - Any new locations need to be added in two places - keep them in sync!
        # - the CLIO OPAC: https://github.com/cul/clio-spectrum/blob/master/lib/holdings/record.rb
        # - the Aeon request script:  /www/data/cu/lso/lib/aeondata.pm
        if ['rbx', 'off,rbx', 'rbms', 'off,rbms', 'rbi', 'uacl', 'uacl,low', 'off,uacl',
            'clm', 'dic', 'dic4off', 'gax', 'oral', 'rbx4off', 'off,dic',
            'off,oral'].include?(location_code)
          return ['spec_coll']
        end

        # ====== ORDERS ======
        # Orders such as "Pre-Order", "On-Order", etc.
        # List of available services per order status hardcoded into yml config file.
        if orders.present?
          orders.each do |order|
            # order_config = ORDER_STATUS_CODES[order[:status_code]]
            # We no longer have the status as lookup key.
            # Do string match againt message found in MARC field to find config.
            order_config = ORDER_STATUS_CODES.values.select do |status_config|
              status_config['short_message'][0, 5] == order[0, 5]
            end.first

            raise 'Status code not found in config/order_status_codes.yml' unless order_config
            services << order_config['services'] unless order_config['services'].nil?
          end
          return services.flatten.uniq
        end

        # ====== ONLINE ======
        # Is this an Online resource?  Do nothing - add no services for online records.
        if item_status[:status] == 'online'
          return services.flatten.uniq
        end

        # Scan for things like "Recall", "Hold", etc.
        services << scan_message(location_name)
        
        # ====== ITEM STATUS "NONE"?? ======
        # Item Status is "none"?  Something's odd, this is not a regular holding.
        # Might be In-Process?
        if item_status[:status] == 'none'
          services << 'in_process' if call_number =~ /in process/i
        end

        # Scan item-status messages for any mention of "Borrow Direct", "ILL", etc.
        services << scan_messages( item_status[:messages] )
     
        # messages = item_status[:messages]
        #
        # case item_status[:status]
        # # when 'online'
        # #   # do nothing - add no services for online records
        # # when 'none'
        # #   # status "none"?  Something's odd, not a regular holding.
        # #   services << 'in_process' if call_number =~ /in process/i
        # when 'available'
        #   services << process_for_services(location_name, location_code, temp_loc_flag, bibid, messages)
        # when 'some_available'
        #   services << process_for_services(location_name, location_code, temp_loc_flag, bibid, messages)
        # # when 'not_available'
        # #   services << scan_messages(messages) if messages.present?
        # end


        # ====== COPY AVAILABLE ======
        # - LOTS of different services are possible when we have an available copy
        if item_status[:status] == 'available' || item_status[:status] == 'some_available'

          # ------ CAMPUS SCAN ------
          # We might soon limit this service by location.
          campus_scan_locations = APP_CONFIG['campus_scan_locations'] || []
          if campus_scan_locations.present?
            services << 'campus_scan' if campus_scan_locations.include?(location_code)
          else
            # But until that's done - add the service for any non-offsite location
            offsite_locations = OFFSITE_CONFIG['offsite_locations'] || []
            services << 'campus_scan' unless offsite_locations.include?(location_code)
          end
          

          # ------ CAMPUS PAGING ------
          # NEXT-1664 / NEXT-1666 - new Paging/Pickup service for available on-campus material
          campus_paging_locations = APP_CONFIG['campus_paging_locations'] || APP_CONFIG['paging_locations'] || ['none']
          services << 'campus_paging' if campus_paging_locations.include?(location_code)

          # ------ RECAP / OFFSITE ------
          # offsite
          offsite_locations = OFFSITE_CONFIG['offsite_locations'] || []
          if offsite_locations.include?(location_code)
            # old-generation Valet service
            services << 'offsite'
            # new-generation Valet services
            # -- recap_loan --
            services << 'recap_loan'
            # -- recap_scan --  (but not for MICROFORM, CD-ROM, etc.)
            unscannable = APP_CONFIG['unscannable_offsite_call_numbers'] || ['none']
            services << 'recap_scan' unless unscannable.any? { |bad| call_number.starts_with?(bad) }
            # TODO - transitional, cleanup old-gen 'offsite'
            services.delete('offsite') if unscannable.any? { |bad| call_number.starts_with?(bad) }
          end
          
          # ------ BEAR-STOR ------
          # If this is a BearStor holding and some items are available,
          # enable the BearStor request link (barnard_remote)
          bearstor_location = APP_CONFIG['barnard_remote_location'] || 'none'
          services << 'barnard_remote' if location_code == bearstor_location
          
          # ------ PRE-CAT ------
          services << 'precat' if location_name =~ /^Precat/
          
        end

        # cleanup the list
        services = services.flatten.uniq


        # TODO
        # This is in-transition, and it's pretty ugly rignt now.
        # The service known within CLIO code as 'ill' is actually Chapter/Article Scan.
        # And this service should be added to ALL physical items (not _online_)
        # no matter their status.
        # Available onsite?  We'll try scan it here.
        # Unavailable? Or indeterminable ("none")?  We'll send it out to ILL for scanning.
        # Either way, CLIO will link out to CGI (or Valet) for Illiad submission
        # services << 'ill' unless item_status[:status] == 'online' or
        # - NO ill/scan for ONLINE records
        # - NO ill/scan if we're already offering offsite/scan service
        if item_status[:status] != 'online' && ! services.include?('offsite')
          services << 'ill'
        end
        

        # We can only ever have ONE "Scan" service.
        services.delete('ill') if services.include?('campus_scan')
        # 8/3 - recap_scan is currently "offsite"
        services.delete('ill') if services.include?('offsite')
        # 8/3 - recap_scan is currently "offsite"

        # # If this is a BearStor holding and some items are available,
        # # enable the BearStor request link (barnard_remote)
        # if location_code == APP_CONFIG['barnard_remote_location'] &&
        #    %w(available some_available).include?(item_status[:status])
        #   services << 'barnard_remote'
        # end

        # # NEXT-1664 - new Paging service
        # # NEXT-1666 - criteria for offering the paging service
        # paging_locations = APP_CONFIG['paging_locations'] || ['glx']
        # if paging_locations.include?(location_code) &&
        #    %w(available some_available).include?(item_status[:status])
        #   services << 'campus_paging'
        # end


        # NEXT-1664 - Criteria for Page/Scan service links
        # If the bibid is in the ETAS database, marked as 'deny', then we have
        # emergency online access - and thus can't offer Scan or Page
        # "Any service that would involve the use of our physical copy should be suppressed"
        if Covid.lookup_db_etas_status(bibid) == 'deny'
          # Scan services ("ill" is actually Chapter/Article-Scan right now)
          services.delete('campus_scan')
          services.delete('offsite')
          services.delete('recap_scan')
          # Pick-up services
          services.delete('campus_paging')
          services.delete('recap_loan')
          # We're still allowed to offer services for non-CUL material,
          # so ILL (ILL Scan and ILL Loan) and BD are still ok.
        end

        # only provide borrow direct request for printed books and scores
        # and CDs and DVDS (LIBSYS-1327)
        # https://www.loc.gov/marc/bibliographic/bdleader.html
        # leader 06 - Type of record
        # a = Language material
        # c = Notated music
        # g = Projected medium
        # j = Musical sound recording
        # leader 07 - Bibliographic level
        # m = Monograph/Item
        # unless fmt == 'am' || fmt == 'cm'
        services.delete('borrow_direct') unless %w(am cm gm jm).include?(fmt)

        # NEXT-1470 - Suppress BD and ILL links for Partner ReCAP items,
        # but leave enabled for CUL offsite.
        if ['scsbnypl', 'scsbpul'].include? location_code
          if Rails.env == 'clio_prod'
            # NEXT-1555 - Valet Borrow Direct
            # services.delete('borrow_direct')
            services.delete('ill')
          end
        end

        Rails.logger.debug("determine_services(#{location_name}, #{location_code}, #{temp_loc_flag}, #{call_number}, #{item_status}, #{orders}, #{bibid}, #{fmt}) found: #{services}")

        # return the cleaned up list
        services
      end

      # def process_for_services(location_name, location_code, temp_loc_flag, _bibid, messages)
      #   services = []
      #
      #   # offsite
      #   if OFFSITE_CONFIG['offsite_locations'].include?(location_code)
      #     # old-generation Valet service
      #     services << 'offsite'
      #     # new-generation Valet services
      #     services << 'recap_loan'
      #     services << 'recap_scan'
      #
      #   # precat
      #   elsif location_name =~ /^Precat/
      #     services << 'precat'
      #
      #   # LIBSYS-3075 - Scan & Deliver ("doc_delivery") is going away forever
      #   # # doc delivery
      #   # # LIBSYS-1365 - Geology is closing, some services are no longer offered
      #   # # NEXT-1502 - Barnard is moving this summer, all items are unavailable
      #   # # elsif ['ave', 'avelc', 'bar', 'bar,mil', 'bus', 'eal', 'eax', 'eng',
      #   # #        'fax', 'faxlc', 'glg', 'glx', 'glxn', 'gsc', 'jou',
      #   # #        'leh', 'leh,bdis', 'mat', 'mil', 'mus', 'sci', 'swx',
      #   # #        'uts', 'uts,per', 'uts,unn', 'war' ].include?(location_code) &&
      #   # #        temp_loc_flag == 'N'
      #   # elsif Array(doc_delivery_locations).include?(location_code) &&
      #   #       temp_loc_flag == 'N'
      #   #   services << 'doc_delivery'
      #
      #   end
      #
      #   services << scan_messages(messages) if messages.present?
      #
      #   services
      # end
            
      # def doc_delivery_locations
      #   # If an override list of doc_delivery_locations was
      #   # defined in app_config, use that.
      #   if APP_CONFIG['doc_delivery_locations'] &&
      #      APP_CONFIG['doc_delivery_locations'].is_a?(Array) &&
      #      APP_CONFIG['doc_delivery_locations'].size > 0
      #     return APP_CONFIG['doc_delivery_locations']
      #   end
      #
      #   # Otherwise, use the default list.
      #   return ['ave', 'avelc', 'bus', 'eal', 'eax', 'eng',
      #           'fax', 'faxlc', 'glx', 'glxn', 'gsc', 'jou',
      #           'leh', 'leh,bdis', 'mat', 'mil', 'mus', 'sci', 'swx',
      #           'uts', 'uts,per', 'uts,unn', 'war']
      # end

      def scan_messages(messages = [])
        return [] unless messages
        services = []
        messages.each do |message|
          # status code 0 == "status unknown"
          next if message[:status_code] == '0'
          # status patrons
          if message[:status_code] == 'sp'
            services << scan_message(message[:long_message])
          else
            status_code_config = ITEM_STATUS_CODES[message[:status_code]]
            raise "Status code '#{message[:status_code]}' not found in ITEM_STATUS_CODES" unless status_code_config
            services << status_code_config['services'] unless status_code_config['services'].nil?
          end
        end
        services
      end

      # Scan item message string for things like "Recall", "Hold", etc.
      def scan_message(message = '')
        return [] unless message
        out = []
        out << 'recall_hold'    if message =~ /Recall/i
        out << 'recall_hold'    if message =~ /hold /
        out << 'borrow_direct'  if message =~ /Borrow/
        out << 'ill'            if message =~ /ILL/
        out << 'in_process'     if message =~ /In Process/
        out << 'ill'            if message =~ /Interlibrary Loan/
        out
      end


      # # LIBSYS-2219
      # # "Materials in the leh,ref and parts of leh (call numbers A* – E*) will be unavailable"
      # def moldy?
      #   return false unless @location_code
      #
      #   return true if @location_code == 'leh,ref'
      #
      #   return false unless @call_number
      #   return true if @location_code == 'leh' && @call_number.first.match(/[A-E]/)
      #
      #   return false
      # end
      

      # def soggy?
      #   # Ignore unless it's an East Asian holding
      #   return false unless %w(eal eax).include? @location_code
      #
      #   call_number_normalized = Lcsort.normalize(@call_number)
      #   # Some call-numbers cannot be normalized, usually because
      #   # they have qualifying prefixes.
      #   #   e.g., "SPECIAL COLL. JQ1629.E8 S56 1900 SCROLLJ"
      #   return if call_number_normalized.blank?
      #
      #   @@wet_ranges ||= get_wet_ranges
      #   @@wet_ranges.each do |range|
      #     # we may be > or >=, depending on the operator
      #     if range[:from_operator] == 'at'
      #       next if call_number_normalized < range[:from_callno]
      #     else
      #       next if call_number_normalized <= range[:from_callno]
      #     end
      #     # we may be < or <=, depending on the operator
      #     if range[:to_operator] == 'at'
      #       next if call_number_normalized > range[:to_callno]
      #     else
      #       next if call_number_normalized >= range[:to_callno]
      #     end
      #     # if we ever get here, then YES, we think it's wet!
      #     return true
      #   end
      #   # Nope, never fell within any of our wet ranges
      #   false
      # end


      # def get_wet_ranges
      #   # Rails.logger.debug "W W W W W W W W W W W W W  called get_wet_ranges()"
      #   raw = YAML.load(File.read(Rails.root.to_s + '/config/wet_ranges.yml'))
      #   # Rails.logger.debug "WWWWWWWWWWWWW  raw.keys=[#{raw.keys}]"
      #
      #   # Accumulate ranges in this array
      #   wet_ranges = []
      #
      #   raw['wet_ranges'].each do |raw|
      #     raw_from, raw_to = raw.split(/\|/)
      #     # Rails.logger.debug "WWWWWWWWWWWWW  raw_from=[#{raw_from}] raw_to=[#{raw_to}]"
      #
      #     # normalize 'From'
      #     from_operator = 'at'
      #     from_callno = Lcsort.normalize(raw_from)
      #     if raw_from.start_with?('After')
      #       from_callno = Lcsort.normalize(raw_from.sub(/After /, ''))
      #       from_operator = 'after'
      #     end
      #     # normalize 'To'
      #     to_operator = 'at'
      #     to_callno = Lcsort.normalize(raw_to)
      #     if raw_to.start_with?('Before')
      #       to_callno = Lcsort.normalize(raw_to.sub(/Before /, ''))
      #       to_operator = 'before'
      #     end
      #
      #     if from_callno.blank? || to_callno.blank?
      #       Rails.logger.error "Unparseable call-numbers: raw_from=[#{raw_from}] raw_to=[#{raw_to}]"
      #       next
      #     end
      #
      #     range = {
      #       from_callno:     from_callno,
      #       from_operator:   from_operator,
      #       to_callno:       to_callno,
      #       to_operator:     to_operator
      #     }
      #     wet_ranges.push(range)
      #   end
      #
      #   wet_ranges
      # end
      
      
    end
  end
end
