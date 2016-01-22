module LocalSolrHelperExtension
  extend ActiveSupport::Concern
  include Blacklight::SearchHelper
  include BlacklightRangeLimit::SegmentCalculation




  #   # OVERRIDE Blacklight::Solr::SearchBuilder#add_facet_fq_to_solr(),
  #   # so support negative facets (prefaced with '-')
  #   # 
  #   # Add any existing facet limits, stored in app-level HTTP query
  #   # as :f, to solr as appropriate :fq query.
  # def add_facet_fq_to_solr(solr_parameters, user_params)
  # 
  #   # convert a String value into an Array
  #   if solr_parameters[:fq].is_a? String
  #     solr_parameters[:fq] = [solr_parameters[:fq]]
  #   end
  # 
  #   # :fq, map from :f.
  #   if user_params[:f]
  #     f_request_params = user_params[:f]
  # 
  #     solr_parameters[:fq] ||= []
  # 
  #     facet_list = f_request_params.keys.map { |ff| ff.gsub(/^-/, '') }.uniq.sort
  # 
  #     facet_list.each do |facet_key|
  #       values = Array(f_request_params[facet_key]).reject(&:empty?)
  # 
  #       excluded_values = Array(f_request_params["-#{facet_key}"])
  #       operator = user_params[:f_operator] && user_params[:f_operator][facet_key] || 'AND'
  #       solr_parameters[:fq] |= facet_value_to_fq_string(facet_key, values, excluded_values, operator)
  #     end
  #   end
  # end


  # def facet_value_to_fq_string(facet_field, values = [], excluded_values = [], operator = 'AND')
  #   values = Array.wrap(values)
  #   excluded_values = Array.wrap(excluded_values)
  # 
  #   results = []
  #   values.each do |value|
  #     results << individual_facet_value_to_fq_string(facet_field, value, operator)
  #   end
  # 
  #   excluded_values.each do |value|
  #     results << individual_facet_value_to_fq_string("-#{facet_field}", value, operator)
  #   end
  # 
  #   results = ["(#{results.join(" OR ")})"] if operator == 'OR'
  # 
  #   results
  # end

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

    query = Deprecation.silence(Blacklight::RequestBuilders) do
      search_builder.
       with(params).
       query(
         extra_controller_params.merge(
           solr_documents_by_field_values_params(field, values)
         )
       )
    end

    solr_response = repository.search(query)

    [solr_response, solr_response.documents]

  end

end
