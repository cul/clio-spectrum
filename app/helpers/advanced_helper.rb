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
    search_as_hidden_fields(:omit_keys => [:q, :show_advanced, :search_field, :qt, :page, :categories, :advanced_operator, :advanced]).html_safe         
  end

  def selected_values_for_facet(facet, localized_parms = params)

    Array.wrap(params[:f] && params[:f][facet])
  end

  def selected_negative_values_for_facet(facet, localized_params = params)
    Array.wrap(params[:f] && params[:f]["-#{facet}"])
  end


  def find_advanced_value(field_name, search_field_name = field_name, localized_params = params)
    (localized_params['advanced'] && localized_params['advanced'][field_name]) || (search_field_name && localized_params['search_field'] == search_field_name && localized_params[:q]) || ""
  end


  # Standard display of a SELECTED facet value, no link, special span
  # with class, and 'remove' button.
  def render_selected_facet_value_on_facet(facet_solr_field, item)
    
    #Updated class for Bootstrap Blacklight 
    content_tag(:span, render_facet_value(facet_solr_field, item, :suppress_link => true), :class => "selected") +
      link_to(content_tag(:i, '', :class => "icon-remove") +  content_tag(:span, '[remove]', :class => 'hide-text'), catalog_index_path(remove_facet_params(facet_solr_field, item, params)), :class=>"remove")
  end
  
end
