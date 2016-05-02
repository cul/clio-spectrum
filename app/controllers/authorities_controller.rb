
class AuthoritiesController < ApplicationController

  def author
    safe_authorized_form = params['author'].gsub(/"/, '\"')
    solr_params = { 
      qt: 'select',
      rows: 1,
      q: "author_t:\"#{safe_authorized_form}\"",
      fl: "id,author_t,author_variant_t",
      facet: 'off'
    }

    @authorities_solr ||= RSolr.connect(url: APP_CONFIG['authorities_solr_url'])

    response = @authorities_solr.get 'select', params: solr_params

raise

  end

  # 
  # # def subject
  # # end
  # 
  # private
  # 
  # # def authority_params
  # #   params.permit(:id)
  # # end

end
