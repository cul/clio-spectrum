module LocalSolrHelperExtension
  extend ActiveSupport::Concern
  include Blacklight::SearchHelper
  include BlacklightRangeLimit::SegmentCalculation


  def remove_range_params(range_key, source_params = params)
    p = source_params.deep_clone
    # need to dup the facet values too,
    # if the values aren't dup'd, then the values
    # from the session will get remove in the show view...
    p.delete :page
    p.delete :id
    p.delete :counter
    p.delete :commit
    p[:range] && p[:range].delete(range_key)
    p
  end

  # copies the current params (or whatever is passed in as the 3rd arg)
  # removes the field value from params[:f]
  # removes the field if there are no more values in params[:f][field]
  # removes additional params (page, id, etc..)
  def remove_facet_params(field, item, source_params = params)
    if item.respond_to? :field
      field = item.field
    end

    value = facet_value_for_facet_item(item)

    p = source_params.dup
    # need to dup the facet values too,
    # if the values aren't dup'd, then the values
    # from the session will get remove in the show view...
    p[:f] = (p[:f] || {}).dup
    p[:f][field] = (p[:f][field] || []).dup
    p.delete :page
    p.delete :id
    p.delete :counter
    p.delete :commit
    p[:f][field] = p[:f][field] - [value]
    p[:f].delete(field) if p[:f][field].size == 0
    p
  end


  # This is getting deprecated from Blacklight
  def get_solr_response_for_field_values(field, values, extra_controller_params = {})

    # solr_response = query_solr(params, extra_controller_params.merge(solr_documents_by_field_values_params(field, values)))
    # 
    # [solr_response, solr_response.documents]

    # Updated Blacklight 5.10.x version of this deprecated function...

    query =
search_builder.with(params).merge(extra_controller_params).merge(solr_documents_by_field_values_params(field, values))

    solr_response = repository.search(query)

    [solr_response, solr_response.documents]

  end

end
