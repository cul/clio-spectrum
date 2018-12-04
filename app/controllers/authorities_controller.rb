
class AuthoritiesController < ApplicationController
  layout 'no_sidebar_no_search'

  def index
    @documents = get_authority_records(params) if params['q'].present?
  end

  def show
  end

  def author
    @document = get_author(params)
  end

  def author_marc
    @document = get_author(params)
  end

  private

  def get_authority_records(params)
    safe_q = params['q'].gsub(/"/, '\"')
    solr_params = {
      qt: 'select',
      q: safe_q,
      fl: 'id,author_t,subject_t,marc_display',
      wt: 'ruby',
      facet: 'off'
    }

    @authorities_solr ||= RSolr.connect(url: APP_CONFIG['authorities_solr_url'])
    response = @authorities_solr.get 'select', params: solr_params

    response['response']['docs']
  end

  def get_author(params)
    safe_authorized_form = params['author'].gsub(/"/, '\"')
    solr_params = {
      qt: 'select',
      rows: 1,
      q: "author_t:\"#{safe_authorized_form}\"",
      fl: 'id,author_t,author_variant_t,marc_display',
      wt: 'ruby',
      facet: 'off'
    }

    @authorities_solr ||= RSolr.connect(url: APP_CONFIG['authorities_solr_url'])
    response = @authorities_solr.get 'select', params: solr_params

    solr_document_hash = response['response']['docs'].first.with_indifferent_access

    # fix Solr schema problems...
    solr_document_hash[:marc_display] = solr_document_hash[:marc_display].first if solr_document_hash[:marc_display].is_a? Array

    @document = SolrDocument.new(solr_document_hash)
    @document
  end
end
