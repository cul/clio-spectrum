module CulFacetsHelper
  def render_filter_element(facet, values, localized_params)
    is_negative = (facet =~ /^-/) ? "NOT " : ""
    proper_facet_name = facet.gsub(/^-/, "")

    facet_config = facet_configuration_for_field(proper_facet_name)

    values.map do |val|

      render_constraint_element( facet_field_labels[proper_facet_name],
                  is_negative + facet_display_value(proper_facet_name, val), 
                  :remove => url_for(remove_facet_params(facet, val, localized_params)),
                  :classes => ["filter", "filter-" + proper_facet_name.parameterize] 
                ) + "\n"                 					            
    end
    
  end

  def expand_all_facets?
    session['options'] && session['options']['always_expand_facets'] == 'true'
  end

end
