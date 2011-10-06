module GenericFacetsHelper
  def facet_paginator(facet)
    Blacklight::Solr::FacetPaginator.new(facet[:items], :limit => facet[:limit])
  end


  def display_facet_item_label(item, value = :not_selected)
    label = item[:label].to_s
    label = "NOT " + label if value == :negated
    label += " (#{number_with_delimiter(item[:count], :delimiter => ".")})" if value == :not_selected
    content_tag(:span, "#{label}", :class => 'facet_label')
  end

  def display_facet_item(item)
    case item[:status]
    when :selected
      content_tag(:li, image_tag("icons/facet_cancel.png",  :class => "facet_cancel facet_action", :size => "14x14", :href => facet_item_command(item, :remove)) + display_facet_item_label(item, :selected), :class => "facet_selected")
    when :negated
      content_tag(:li, image_tag("icons/facet_cancel.png", :class => "facet_cancel facet_action", :size => "14x14", :href => facet_item_command(item, :remove)) + display_facet_item_label(item, :negated), :class => "facet_negated")
    when :not_selected

      content_tag(:li, 
                  image_tag("icons/facet_plus.png", :class => "facet_plus facet_action", :size => "14x14", :href => facet_item_command(item, :select)) + 
                  image_tag("icons/facet_minus.png", :class => "facet_minus facet_action", :size => "14x14", :href => facet_item_command(item, :negate)) + 
                  display_facet_item_label(item, :not_selected), :class => "facet_not_selected")
    end
  end

  def display_facet_items(facet, status)
    facet.items(status).collect { |i| display_facet_item(i) }.join("").html_safe
  end

  def facet_item_command(item, command)
    article_search_path(@search.query.to_hash.merge(item[:commands][command]))
  end
end
