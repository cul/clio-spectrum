module AdvancedHelper
  def change_params_and_redirect(changed_params, reg_params = params)
    new_params = reg_params.deep_clone
    new_params.delete(:page)

    Blacklight::Solr::FacetPaginator.request_keys.values.each do |paginator_key|
      new_params.delete(paginator_key)
    end

    new_params.delete(:id)

    # new_params[:action] = 'index'
    # "Calling URL helpers with string keys controller, action is deprecated"
    new_params.delete(:controller)
    new_params.delete(:action)

    new_params.merge!(changed_params)
    new_params
  end

  def standard_hidden_keys_for_search
    # # advice from:  https://groups.google.com/forum/#!topic/hydra-tech/4PeyyiZ8VNY
    # # search_as_hidden_fields(omit_keys: [:q, :search_field, :qt, :page, :categories, :advanced_operator, :adv, :advanced]).html_safe
    # omit = [:q, :search_field, :qt, :page, :categories,
    #         :advanced_operator, :adv, :advanced]
    # # http://apidock.com/rails/Hash/except#1507-Passing-an-array-of-keys-to-exclude-
    # render_hash_as_hidden_fields(params_for_search.except(*omit))

    # BL 6
    render_hash_as_hidden_fields(search_state.params_for_search.except(:q, :search_field, :qt, :page, :utf8, :categories,
            :advanced_operator, :adv, :advanced))
  end

# Unused?
#   def selected_values_for_facet(facet, localized_parms = params)
#     Array.wrap(params[:f] && params[:f][facet])
#   end

  def selected_negative_values_for_facet(facet, localized_params = params)
    Array.wrap(params[:f] && params[:f]["-#{facet}"])
  end

  # Standard display of a SELECTED facet value, no link, special span
  # with class, and 'remove' button.
  def render_selected_facet_value_on_facet(facet_solr_field, item)
    # Updated class for Bootstrap Blacklight
    content_tag(:span, render_facet_value(facet_solr_field, item, suppress_link: true), class: 'selected') +
      link_to(content_tag(:span, '', class: 'glyphicon glyphicon-remove') +  content_tag(:span, '[remove]', class: 'hide-text'), search_catalog_path(remove_facet_params(facet_solr_field, item, params)), class: 'remove')
  end

  def advanced_field_text_field(blacklight_config, index, par = params)
    index = index.to_s
    default_value = params['adv'] && params['adv'][index] && (!params['adv'][index]['field'].to_s.empty? && params['adv'][index]['value'])

    text_field_tag("adv[#{index}][value]", default_value,  class: 'form-control')
  end

  # builds the field select-tag for each Advanced Search field/value pair (for Catalog)
  def advanced_field_select_option(blacklight_config, index, par = params)
    index = index.to_s
    field_list = blacklight_config.search_fields.map do |field_key, field|
      [field.label, field_key]
    end

    # omit the "select" message, just default to "any field"
    # field_list = [["Select a field...", ""]] | field_list

    default_value = params['adv'] &&
                    params['adv'][index] &&
                    (!params['adv'][index]['value'].to_s.empty? &&
                      params['adv'][index]['field'])
    default_value ||= 'all_fields'
    select_tag("adv[#{index}][field]", options_for_select(field_list, default_value), class: 'form-control')
  end

  def has_advanced_params?
    # Catalog
    return true if params[:adv].kind_of?(Hash) && !params[:adv].empty?
    # Summon
    return true if params[:form] == 'advanced'
    # If we didn't detect any advanced search...
    false
  end
end
