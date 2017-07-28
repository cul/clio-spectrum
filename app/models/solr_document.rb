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
    # Columbia bib ids are numeric, partner data is "SCSB-xxxx"
    return ! id.start_with?('SCSB')
  end

  # Does this Solr Document have Holdings data within it's MARC fields?
  def has_marc_holdings?
    # mfhd_id is a repeated field, once per holding.
    # we only care if it's present at all.
    return self.has_key?(:mfhd_id) && self.has_key?(:barcode_txt)
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
