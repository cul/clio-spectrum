class SolrDocument
  attr_accessor :item_alerts

  # method signiture copied from module Blacklight::Document
  def initialize(source_doc = {}, response = nil)
    super(source_doc, response)

    # item_alert hash has to be ready for access by type
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
    return false unless ['development', 'clio_test'].include?(Rails.env)
    return false unless tag = self.to_marc['965']
    return tag.value == 'BACKSTAGE_TEST'
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
  
  def to_xls
    fields = {'title' => 'title_display', 'author' => 'author_display', 'publisher' => 'full_publisher_display'}
    
    output = "<Row>\n"
    fields.values.each do |field_name|
      output += "<Cell><Data ss:Type='String'>\n"
      output += Array(self[field_name]).join('; ')
      output += "</Data></Cell>\n"
    end
    
    output += "</Row>\n"
  end

  def to_xlsx(level = 'bib')
    # level is one of:  bib, holding, item
    
    bib_fields = {
      'title'       => 'title_display',
      'author'      => 'author_display',
      'publisher'   => 'full_publisher_display',
      'ISBN'        => 'isbn_display',
    }
    holding_fields = {
      
    }
    item_fields = {
      
    }

    # 1 or more rows, depending on level (bib, holding, item)
    doc_rows = []

    # value accumulator arrays
    bib_values = holding_values = item_values =  []

    # gather bib_values - bib-level metadata
    bib_fields.each do |field_header, field_name|
      field_value = Array(self[field_name]).join("; ")
      bib_values << field_value
    end
    
    # first column is always a link to the CLIO page
    bib_values.unshift("https://clio.columbia.edu/catalog/#{self.id}")
    
    if level == 'bib'
      doc_rows << bib_values
    elsif level == 'holding' || level == 'item'
      # loop over each holding 
      # Solr data doesn't support this kind of detail
    end

    return doc_rows
  end

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
