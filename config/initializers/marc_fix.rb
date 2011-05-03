module Blacklight::Solr::Document::Marc
  protected
  def load_marc
    case _marc_format_type.to_s
    when 'marcxml'
      records = MARC::XMLReader.new(StringIO.new( fetch(_marc_source_field) )).to_a
      return records[0]
    when 'marc21'
      return MARC::Record.new_from_marc( fetch(_marc_source_field).gsub("#30;",30.chr).gsub("#31;",31.chr))          
    else
      raise UnsupportedMarcFormatType.new("Only marcxml and marc21 are supported.")
    end      
  end



end
