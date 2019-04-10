class SolrDocument
  attr_accessor :item_alerts, :active_item_alert_count

  # method signiture copied from module Blacklight::Document
  def initialize(source_doc = {}, response = nil)
    super(source_doc, response)

    # item_alert hash has to be ready for access by type
    self.active_item_alert_count = 0
    self.item_alerts = HashWithIndifferentAccess.new
    ItemAlert::ALERT_TYPES.each do |alert_type, _label|
      item_alerts[alert_type] = []
    end
  end

  def id
    # Cope with GeoBlacklight SolrDocuments
    self[:layer_slug_s] || self[self.class.unique_key]
    # self[self.class.unique_key].listify.first
  end

  include Blacklight::Solr::Document

  def cache_key
    "SolrDocument_#{id}_#{self['timestamp']}"
  end

  # Convenience method for enabling database-specific styling
  def is_database?
    key?('source_display') &&
      Array(self['source_display']).include?('database')
  end

  # Is this a Columbia record?  (v.s. ReCAP partner record)
  def columbia?
    # Columbia bib ids are numeric, or numeric with 'b' prefix for Law,
    # ReCAP partner data is "SCSB-xxxx"
    !id.start_with?('SCSB')
  end

  # Detect Law records, cataloged in Pegasus (https://pegasus.law.columbia.edu/)
  def in_pegasus?
    # Document must have an id, which must be a "b" followed by a number...
    return false unless id && id.match(/^b\d{2,9}$/)

    # And, confirm that the Location is "Law"

    # pull out the Location/call-number/holdings-id field...
    return false unless location_call_number_id = self[:location_call_number_id_display]
    # unpack, and confirm each occurrance ()
    Array.wrap(location_call_number_id).each do |portmanteau|
      location = portmanteau.partition(' >>').first
      # If we find any location that's not Law, this is NOT pegasus
      return false if location && location != 'Law'
    end

    true
  end

  # Access our holdings, from the holdings_ss Solr field
  # subfields serialized as:   |code|value
  # concatenated together, e.g.:  
  #   |0|144|a|Butler Stacks (Enter at the Butler Circulation Desk)|b|glx|h|PG7178.O45 P5
  #
  # >> solr_doc['holdings_ss']
  # => ["|0|144|a|Butler Stacks (Enter at the Butler Circulation Desk)|b|glx|h|PG7178.O45 P5"]
  # 
  # >> solr_doc.holdings
  # => [{"0"=>"144", "a"=>"Butler Stacks (Enter at the Butler Circulation Desk)", "b"=>"glx", "h"=>"PG7178.O45 P5"}]

  def holdings
    holdings = []
    Array(self['holdings_ss']).each do |serialized|
      holding = Hash.new()
      serialized.scan(/\|(\w)\|([^\|]*)/) { |code, value|
        holding[code] = value
      }
      holdings << holding
    end
    return holdings
  end

  # Return the list of all items for this solr document,
  # or, if holding_id is passed in, return all items for that holding
  #
  # >> solr_doc.items
  # => [{"0"=>"144", "a"=>"540", "p"=>"0109179160"}]
  # >> solr_doc.items('144')
  # => [{"0"=>"144", "a"=>"540", "p"=>"0109179160"}]
  # 
  def items(holding_id)
    holding_id = holding_id.to_s
    items = []
    Array(self['items_ss']).each do |serialized|
      item = Hash.new()
      serialized.scan(/\|(\w)\|([^\|]*)/) { |code, value|
        item[code] = value
      }
      items << item if holding_id.blank? || holding_id == item['0']
    end
    return items
  end

  # Does this Solr Document have Holdings data within it's MARC fields?
  def has_marc_holdings?
    # mfhd_id is a repeated field, once per holding.
    # we only care if it's present at all.
    return false unless key?(:mfhd_id)

    # We have a Holding -- return true
    true
  end

  # Does Voyager have live circ status for this document?
  def has_circ_status?
    # Only Columbia items will be found in our local Voyager
    return false unless columbia?
    # Pegasys (Law) will not have circ status
    return false if in_pegasus?

    # Online resources have a single Holdings record & no Item records
    # They won't have any circulation status in Voyager
    return false if key?(:location_txt) &&
                    self[:location_txt].size == 1 &&
                    self[:location_txt].first.starts_with?('Online')

    # If we hit a document w/out MARC holdings, it won't have circ status either.
    # This shouldn't happen anymore.
    unless has_marc_holdings?
      Rails.log.warn "Columbia bib record #{id} has no MARC holdings"
      return false
    end

    # Even if the bib has holding(s), there may be no item records.
    # If there are no items at all, we can't fetch circ status.
    return false if key?(:items_i) && (self[:items_i]).zero?

    # But the circ_status SQL code will still work for non-barcoded items,
    # and report items as 'Available'.
    # So why not just let it run?  We have no evidence of unavailability,
    # we may as well trust the 'available' status, and let unavailability be
    # reported through normal workflow.
    # # Only documents with barcoded items are tracked in Voyager circ system
    # return self.has_key?(:barcode_txt)

    true
  end

  # This triggers a call to fetch real time availabilty from the SCSB API
  def has_offsite_holdings?
    return false unless self[:location_facet].present?

    # string regexp against the location field
    self[:location_facet].each do |location_facet|
      return true if location_facet =~ /^Offsite/
      return true if location_facet =~ /ReCAP/i
      # (this should not really happen)
      return true if location_facet =~ /scsb/i
    end

    # No offsite location found
    false
  end

  # Does this item have any holdings in non-offsite locations?
  def has_onsite_holdings?
    return false unless self[:location_facet].present?

    # consider each location for this record....
    self[:location_facet].each do |location_facet|
      # skip over anything that's offsite...
      next if location_facet =~ /^Offsite/
      next if location_facet =~ /ReCAP/i

      # skip over Online locations (e.g., just links)
      next if location_facet =~ /Online/i

      # If we got here, we found somthing that's onsite!
      return true
    end

    # If we dropped down to here, we only found offsite locations.
    false
  end

  def call_numbers
    Array(self['call_number_display']).sort.uniq.join(' / ')
  end

  # The following shows how to setup this blacklight document to display marc documents
  extension_parameters[:marc_source_field] = :marc_display
  extension_parameters[:marc_format_type] = :marcxml
  use_extension(Blacklight::Solr::Document::Marc) do |document|
    document.key?(:marc_display)
  end

  # temporary testing in CLIO Test environment ONLY
  def backstage?
    return false if Rails.env == 'clio_prod'
    return false unless tag = self.to_marc['965']
    return tag.value.match /backstage/i
  end
  
  # # CSV DOWNLOAD SUPPORT
  # 
  # # mapping of column headers to SolrDocument field names
  # CSV_BIB_FIELDS = {
  #   'title'      =>  'title_display',
  #   'author'     =>  'author_display',
  #   'publisher'  =>  'full_publisher_display',
  # }
  # 
  # # To get a simple array of strings to use for CSV header row:
  # #   SolrDocument.csv_headers
  # def self.csv_headers
  #   bib_headers = CSV_BIB_FIELDS.keys.map { |header| header.titleize }
  #   return bib_headers
  # end
  # 
  # # Customize the mapping of a SolrDocument to CSV output.
  # # Initially, a single fixed row per document.
  # # Potentially, customizable data fields, and a rows for each holding or item.
  # # RETURN  An array of strings, each a valid CSV row of data, newline-terminated.
  # def to_csv
  #   # return an array of rows for the CSV report output
  #   rows = []
  # 
  #   # for now, a simple single row of bib data
  #   values = []
  #   CSV_BIB_FIELDS.each do |field_header, field_name|
  #     field_value = Array(self[field_name]).join('; ')
  #     values << field_value
  #   end
  #   rows << values.to_csv.html_safe
  # 
  #   return rows
  # end
  
  # def to_xls
  #   fields = {'title' => 'title_display', 'author' => 'author_display', 'publisher' => 'full_publisher_display'}
  #   
  #   output = "<Row>\n"
  #   fields.values.each do |field_name|
  #     output += "<Cell><Data ss:Type='String'>\n"
  #     output += Array(self[field_name]).join('; ')
  #     output += "</Data></Cell>\n"
  #   end
  #   
  #   output += "</Row>\n"
  # end

  # level is one of:  bib, holding, item
  def to_xlsx(level = 'bib')

    rows = []
    
    if level == 'bib'
      rows << bib_column_data
      return rows
    end
    
    # Pull out our Holdings list, for 'holding' or 'item' reporting.
    holding_list = self.holdings

    # When bib has no holdings data, use a dummy value.
    holding_list << {'h' => "no holding data"} if holding_list.size == 0
    

    if level == 'holding'

      holding_list.each do |holding|
        # build up a row for this holding
        row = []
        row += bib_column_data
        row += holding_column_data(holding)
        # add this holding's row to the set of rows
        rows << row
      end

    end
      
    if level == 'item'

      holding_list.each do |holding|
        holding_id = holding[0]

        # fetch items for this holding
        item_list = self.items(holding_id)
        # use dummy value if no data present
        item_list << {'p' => "no item data"} if item_list.size == 0

        item_list.each do |item|

          # build up a row for this item
          row = []
          row += bib_column_data
          row += holding_column_data(holding)
          row += item_column_data(item)

          # add this items's row to the set of rows
          rows << row
        end
      end
    end


    return rows


    # holdings.each do |holding|
    #   holding_id = holding['0']
    # 
    #   items(holding_id).each do |item|
    #     
    #   end
    # end
    # 
    # # This doc will output to 1 or more rows, depending on level (bib, holding, item)
    # doc_rows = []
    # 
    # # value accumulator arrays
    # bib_values = holding_values = item_values =  []
    # 
    # # gather bib_values - bib-level metadata
    # bib_columns.each do |field_header, solr_field_name|
    #   field_value = Array(self[solr_field_name]).join("\r\n")
    #   bib_values << field_value
    # end
    # 
    # # first column is always a link to the CLIO page
    # bib_values.unshift("https://clio.columbia.edu/catalog/#{self.id}")
    # 
    # if level == 'bib'
    #   doc_rows << bib_values
    # elsif level == 'holding' || level == 'item'
    #   raise
    #   # loop over each holding 
    #   # Solr data doesn't support this kind of detail
    # end
    # 
    # return doc_rows
  end

  def bib_column_data
    data = []
    SolrDocument.bib_columns.each do |column_header, column_key|
      data << Array(self[column_key]).join("\r\n")
    end
    return data
  end
  
  def holding_column_data(holding)
    data = []
    SolrDocument.holding_columns.each do |column_header, column_key|
      # computed column values...
      if column_key[0] == '#'
        compute_function = column_key[1..-1]
        data << self.send(compute_function, holding)
        next
      end
      # direct subfield columns values...
      data << Array(holding[column_key]).join("\r\n")
    end
    return data
  end

  def item_column_data(item)
    data = []
    SolrDocument.item_columns.each do |column_header, column_key|
      data << Array(item[column_key]).join("\r\n")
    end
    return data
  end
  def self.column_headers(level = 'bib')
    headers = []
    headers += bib_columns.keys
    headers += holding_columns.keys if level == 'holding' || level == 'item'
    headers += item_columns.keys if level == 'item'
    return headers
  end
  def self.bib_columns
    {
      'Bib ID'               => 'id',
      'Title'                => 'title_display',
      'Author'               => 'author_display',
      'Publisher'            => 'full_publisher_display',
      'Publication Year'     => 'pub_year_display',
      'ISBN'                 => 'isbn_display',
      'Physical Description' => 'physical_description_display',
    }
  end
  def self.holding_columns
    { 
      'Holding ID'    =>   '0',
      'Location'      =>   'a',
      'Location Code' =>   'b',
      'Call Number'   =>   'h',
      'Sortable Call Number'   =>   '#sortable_call_number',
    }
  end
  def self.item_columns
    { 
      'Barcode'                  =>   'p',
      'Enum / Chron'             =>   '3',
      'Item Temp Location'       =>   'l',
      'Item Temp Location Code'  =>   'm',
    }
  end
  
  def sortable_call_number(holding)
    return '' unless holding
    call_number = holding['h']
    return '' unless call_number
    normalized_call_number = Lcsort.normalize(call_number)
    return normalized_call_number if normalized_call_number
    return call_number
  end

  def to_rows(level = 'bib')
    case level
    when 'bib'
     to_bib_row
    when 'holding'
     to_holding_rows
    when 'item'
     to_item_rows 
    end
  end

  def to_bib_row
    bib_fields = {
      'title'       => 'title_display',
      'author'      => 'author_display',
      'publisher'   => 'full_publisher_display',
      'ISBN'        => 'isbn_display',
    }

    bib_row = []
    bib_fields.each do |field_header, field_name|
      field_value = Array(self[field_name]).join("\r\n")
      bib_row << field_value
    end
    
    # first column is always a link to the CLIO page
    bib_values.unshift("https://clio.columbia.edu/catalog/#{self.id}")
    return bib_row
  end

  def to_holding_rows
    bib_row = self.to_bib_row
    holdings = self.holdings
    # handle records w/out holdings data
    return bib_row.shift('No holdings data') if holdings.count == 0
    
    holdings.each do |holding|
      row = []
      rows << bib_row
      row << holding
      
    end
    return holding_rows
  end
    
    
    
    
  #   bib_data = hold
  #   bib_data = self.bib_data
  #   
  #   if level == 'holding' || level == 'item'
  #     self.holdings.each do |holding|
  #       holding_data = 
  #     end
  #   end
  #   
  # end

  # At Columbia, these are replaced by code within the record_mailer views
  # # Email uses the semantic field mappings below to generate the body of an email.
  # SolrDocument.use_extension( Blacklight::Solr::Document::Email )

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core

  #  these are the DC fields you can play with...
  #  :contributor, :coverage, :creator, :date, :description, :format, :identifier, :language, :publisher, :relation, :rights, :source, :subject, :title, :type

  use_extension(Blacklight::Document::DublinCore)
  field_semantics.merge!(
    # :identifier => "id",  # suggested mapping is ISBN or ISSN
    title: 'title_display',
    author: 'author_display',
    contributor: 'author_display',
    publisher: 'full_publisher_display',
    language: 'language_facet',
    format: 'format',
    date: 'pub_date_sort'
  )
end
