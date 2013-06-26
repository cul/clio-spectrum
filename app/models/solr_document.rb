class SolrDocument

  def id
    self[self.class.unique_key].listify.first
  end

  include Blacklight::Solr::Document


  # The following shows how to setup this blacklight document to display marc documents
  extension_parameters[:marc_source_field] = :marc_display
  extension_parameters[:marc_format_type] = :marcxml
  use_extension( Blacklight::Solr::Document::Marc) do |document|
    document.key?( :marc_display  )
  end

  # At Columbia, these are replaced by code within the record_mailer views
  # # Email uses the semantic field mappings below to generate the body of an email.
  # SolrDocument.use_extension( Blacklight::Solr::Document::Email )
  # 
  # # SMS uses the semantic field mappings below to generate the body of an SMS email.
  # SolrDocument.use_extension( Blacklight::Solr::Document::Sms )

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core

#  these are the DC fields you can play with...
#  :contributor, :coverage, :creator, :date, :description, :format, :identifier, :language, :publisher, :relation, :rights, :source, :subject, :title, :type

  use_extension( Blacklight::Solr::Document::DublinCore)
  field_semantics.merge!(
                         # :identifier => "id",  # suggested mapping is ISBN or ISSN
                         :title => "title_display",
                         :contributor => "author_display",
                         :publisher => "full_publisher_display",
                         :language => "language_facet",
                         :format => "format",
                         :date => "pub_date_facet"
                         )
end
