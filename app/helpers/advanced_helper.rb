module AdvancedHelper

  def change_params_and_redirect(changed_params, reg_params=params)
    new_params = reg_params.deep_clone
    new_params.delete(:page)

    Blacklight::Solr::FacetPaginator.request_keys.values.each do |paginator_key|
      new_params.delete(paginator_key)
    end

    new_params.delete(:id)

    new_params[:action] = "index"
    new_params.merge!(changed_params)
    new_params
  end

  def standard_hidden_keys_for_search
    search_as_hidden_fields(:omit_keys => [:q, :show_advanced, :search_field, :qt, :page, :categories, :advanced_operator, :adv, :advanced]).html_safe
  end

  def selected_values_for_facet(facet, localized_parms = params)

    Array.wrap(params[:f] && params[:f][facet])
  end

  def selected_negative_values_for_facet(facet, localized_params = params)
    Array.wrap(params[:f] && params[:f]["-#{facet}"])
  end




  # Standard display of a SELECTED facet value, no link, special span
  # with class, and 'remove' button.
  def render_selected_facet_value_on_facet(facet_solr_field, item)

    #Updated class for Bootstrap Blacklight
    content_tag(:span, render_facet_value(facet_solr_field, item, :suppress_link => true), :class => "selected") +
      link_to(content_tag(:i, '', :class => "icon-remove") +  content_tag(:span, '[remove]', :class => 'hide-text'), catalog_index_path(remove_facet_params(facet_solr_field, item, params)), :class=>"remove")
  end

  def advanced_field_text_field(blacklight_config, index, par=params)
    index = index.to_s
    default_value = params['adv'] && params['adv'][index] && (!params['adv'][index]['field'].to_s.empty? && params['adv'][index]['value'])

    text_field_tag("adv[#{index}][value]",default_value,  :class => "advanced_search_value")

  end
  
  # builds the field select-tag for each Advanced Search field/value pair
  def advanced_field_select_option(blacklight_config, index, par = params)
    index = index.to_s
    field_list = blacklight_config.search_fields.collect do |field_key, field|
      [field.label, field_key]
    end

    # omit the "select" message, just default to "any field"
    # field_list = [["Select a field...", ""]] | field_list
    
    default_value = params['adv'] && 
                    params['adv'][index] && 
                    (!params['adv'][index]['value'].to_s.empty? &&
                      params['adv'][index]['field'])
    select_tag("adv[#{index}][field]", options_for_select(field_list, default_value), :class => "advanced_search_field")
  end
end

