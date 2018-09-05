class SolrDocument

  attr_accessor :item_alerts

  # method signiture copied from module Blacklight::Document
  def initialize(source_doc={}, response=nil)
    super(source_doc, response)

    # item_alert hash has to be ready for access by type
    self.item_alerts = HashWithIndifferentAccess.new
    ItemAlert::ALERT_TYPES.each do |alert_type, label|
      self.item_alerts[alert_type] = []
    end
  end

  def id
    # Cope with GeoBlacklight SolrDocuments
    return self[:layer_slug_s] || self[self.class.unique_key]
    # self[self.class.unique_key].listify.first
  end

  include Blacklight::Solr::Document

  def cache_key
    "SolrDocument_#{id}_#{self['timestamp']}"
  end

  # Convenience method for enabling database-specific styling
  def is_database?
    return self.has_key?('source_display') &&
           Array(self['source_display']).include?("database")
  end

  # Is this a Columbia record?  (v.s. ReCAP partner record)
  def columbia?
    # Columbia bib ids are numeric, or numeric with 'b' prefix for Law,
    # ReCAP partner data is "SCSB-xxxx"
    return ! id.start_with?('SCSB')
  end

  # Detect Law records, cataloged in Pegasus (https://pegasus.law.columbia.edu/)
  def in_pegasus?
    # Document must have an id, which must be a "b" followed by a number...
    return false unless id and id.match /^b\d{2,9}$/
  
    # And, confirm that the Location is "Law"
  
    # pull out the Location/call-number/holdings-id field...
    return false unless location_call_number_id = self[:location_call_number_id_display]
    # unpack, and confirm each occurrance ()
    Array.wrap(location_call_number_id).each do |portmanteau|
      location = portmanteau.partition(' >>').first
      # If we find any location that's not Law, this is NOT pegasus
      return false if location and location != 'Law'
    end
  
    true
  end

  # Does this Solr Document have Holdings data within it's MARC fields?
  def has_marc_holdings?
    # mfhd_id is a repeated field, once per holding.
    # we only care if it's present at all.
    return false unless self.has_key?(:mfhd_id)

    # We have a Holding -- return true
    return true
  end

  # Does Voyager have live circ status for this document?
  def has_circ_status?
    # Only Columbia items will be found in our local Voyager
    return false unless self.columbia?
    # Pegasys (Law) will not have circ status
    return false if self.in_pegasus?

    # Online resources have a single Holdings record & no Item records
    # They won't have any circulation status in Voyager
    return false if self[:location_txt].size == 1 && 
                    self[:location_txt].first.starts_with?("Online")

    # If we hit a document w/out MARC holdings, it won't have circ status either.
    # This shouldn't happen anymore.
    if not self.has_marc_holdings?
      Rails.log.warn "Columbia bib record #{id} has no MARC holdings"
      return false
    end

    # But the circ_status SQL code will still work for non-barcoded items,
    # and report items as 'Available'.
    # So why not just let it run?  We have no evidence of unavailability,
    # we may as well trust the 'available' status, and let unavailability be
    # reported through normal workflow.
    # # Only documents with barcoded items are tracked in Voyager circ system
    # return self.has_key?(:barcode_txt)

    return true
  end

  # This triggers a call to fetch real time availabilty from the SCSB API
  def has_offsite_holdings?
    return false unless self[:location_facet].present?

    # string regexp against the location field
    self[:location_facet].each do |location_facet|
      return true if location_facet.match /^Offsite/
      return true if location_facet.match /ReCAP/i
      # (this should not really happen)
      return true if location_facet.match /scsb/i
    end
    
    # No offsite location found
    return false
  end

  # Does this item have any holdings in non-offsite locations?
  def has_onsite_holdings?
    return false unless self[:location_facet].present?

    # consider each location for this record....
    self[:location_facet].each do |location_facet|
      # skip over anything that's offsite...
      next if location_facet.match /^Offsite/
      next if location_facet.match /ReCAP/i

      # skip over Online locations (e.g., just links)
      next if location_facet.match /Online/i

      # If we got here, we found somthing that's onsite!
      return true
    end
    
    # If we dropped down to here, we only found offsite locations.
    return false
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

  # At Columbia, these are replaced by code within the record_mailer views
  # # Email uses the semantic field mappings below to generate the body of an email.
  # SolrDocument.use_extension( Blacklight::Solr::Document::Email )

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension( Blacklight::Document::Sms )


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
                         author: "author_display",
                         contributor: 'author_display',
                         publisher: 'full_publisher_display',
                         language: 'language_facet',
                         format: 'format',
                         date: 'pub_date_sort'
                         )
end
