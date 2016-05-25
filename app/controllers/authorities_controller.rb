
class AuthoritiesController < ApplicationController

  layout 'no_sidebar'

  def author
    @document = get_document(params)
    # safe_authorized_form = params['author'].gsub(/"/, '\"')
    # solr_params = { 
    #   qt: 'select',
    #   rows: 1,
    #   q: "author_t:\"#{safe_authorized_form}\"",
    #   fl: "id,author_t,author_variant_t,marc_display",
    #   wt: 'ruby',
    #   facet: 'off'
    # }
    # 
    # @authorities_solr ||= RSolr.connect(url: APP_CONFIG['authorities_solr_url'])
    # 
    # response = @authorities_solr.get 'select', params: solr_params
    # 
    # solr_document_hash = response['response']['docs'].first.with_indifferent_access
    # 
    # # fix Solr schema problems...
    # solr_document_hash[:marc_display] = solr_document_hash[:marc_display].first if solr_document_hash[:marc_display].is_a? Array
    # 
    # @document = SolrDocument.new(solr_document_hash)

    # respond_to do |format|
    #   format.html
    #   format.marcview  { render 'author_marc' }
    # end

  end

  # Override Blacklight's definition, to assign custom layout
  def author_marc
    @document = get_document(params)
  end



  private


  def get_document(params)
    safe_authorized_form = params['author'].gsub(/"/, '\"')
    solr_params = { 
      qt: 'select',
      rows: 1,
      q: "author_t:\"#{safe_authorized_form}\"",
      fl: "id,author_t,author_variant_t,marc_display",
      wt: 'ruby',
      facet: 'off'
    }

    @authorities_solr ||= RSolr.connect(url: APP_CONFIG['authorities_solr_url'])

    response = @authorities_solr.get 'select', params: solr_params

    solr_document_hash = response['response']['docs'].first.with_indifferent_access

    # fix Solr schema problems...
    solr_document_hash[:marc_display] = solr_document_hash[:marc_display].first if solr_document_hash[:marc_display].is_a? Array

    @document = SolrDocument.new(solr_document_hash)
    return @document
  end

end
