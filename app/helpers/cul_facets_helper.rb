module CulFacetsHelper
  
  # 
  ##  OVERRIDE Blacklight::FacetsHelperBehavior 
  # 
  # Are any facet restrictions for a field in the query parameters?
  # 
  # @param [String] facet field
  # @return [Boolean]
  # def facet_field_in_params? field
  #   # Support positive or negative, that is, "-location_facet"
  #   params[:f] and ( params[:f][field] || params[:f]["-#{field}"])
  # end
  
  ##
  # Check if the query parameters have the given facet field with the 
  # given value.
  # 
  # @param [Object] facet field
  # @param [Object] facet value
  # @return [Boolean]
  def facet_in_params?(field, item)
    if item and item.respond_to? :field
      field = item.field
    end

    value = facet_value_for_facet_item(item)
    
    return true if facet_field_in_params?(field) and params[:f][field].include?(value)
  
    negated_field = "-#{field}"
    return true if facet_field_in_params?(negated_field) and params[:f][negated_field].include?(value)
    
    return false
  end
  
  
  
  
  # Override core blacklight render_constraints_helper_behavior.rb
  # module Blacklight::RenderConstraintsHelperBehavior#render_filter_element
  def render_filter_element(facet, values, localized_params)
    is_negative = (facet =~ /^-/) ? 'NOT ' : ''
    proper_facet_name = facet.gsub(/^-/, '')

    facet_config = facet_configuration_for_field(proper_facet_name)

    values.map do |val|

      render_constraint_element(
        # facet_field_labels[proper_facet_name],
        facet_field_label(proper_facet_name),
        is_negative + facet_display_value(proper_facet_name, val),
        remove: url_for(remove_facet_params(facet, val, localized_params)),
        classes: ['filter', 'filter-' + proper_facet_name.parameterize]
      ) + "\n"
    end
  end

  def expand_all_facets?
    get_browser_option('always_expand_facets') == 'true'
  end

  def build_facet_tag(facet_field, datasource = @active_source)
    facet_tag = @active_source + '_' + facet_field.field.parameterize
  end


  # Is there something telling us to render this facet as open?
  def render_facet_open?(facet_field, datasource = @active_source)
    # Do we have "Expand All Facets" turned on?
    return true if expand_all_facets?

    # Is the facet itself configured to display as open?
    return true if facet_field && facet_field.respond_to?(:open) && facet_field.open == true

    # NEXT-1028 - Make facet state (open/closed) sticky through a selection
    # Do we have an explicit browser-display setting saved?
    # If so, respect that saved setting ("Sticky").
    facet_tag = build_facet_tag(facet_field, datasource)
    return true if get_browser_option(facet_tag) == 'open'
    return false if get_browser_option(facet_tag) == 'closed'

    # Nothing told us to render this facet as open, so it'll be closed.
    false
  end
end
