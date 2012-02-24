module GenericFacetsHelper
  def facet_paginator(facet)
    Blacklight::Solr::FacetPaginator.new(facet[:items], :limit => facet[:limit])
  end

  def fix_catalog_links(text)
    text.to_s.gsub('/catalog',"/#{datasource_to_class(@active_source)}").html_safe
  end

  def display_facet_item_label(item, value = :not_selected)
    label = item[:label].to_s
    if value == :not_selected
      label = content_tag(:a, label, :href => facet_item_command(item, :select), :class => "facet_plus facet_action").html_safe
    end
    label = "NOT " + label if value == :negated
    if value == :not_selected
      if item[:count].to_i >= 1000000
        label += " (#{item[:count].to_i/1000000}M)"
      else
        label += " (#{number_with_delimiter(item[:count], :delimiter => ".")})" 
      end
    end

    content_tag(:span, "#{label}".html_safe, :class => 'facet_label')
  end

  def display_facet_item(item)
    case item[:status]
    when :selected
      content_tag(:li, image_tag("icons/facet_cancel.png",  :class => "facet_cancel facet_action", :size => "14x14", :href => facet_item_command(item, :remove)) + display_facet_item_label(item, :selected), :class => "facet_selected")
    when :negated
      content_tag(:li, image_tag("icons/facet_cancel.png", :class => "facet_cancel facet_action", :size => "14x14", :href => facet_item_command(item, :remove)) + display_facet_item_label(item, :negated), :class => "facet_negated")
    when :not_selected

      content_tag(:li, 
                  display_facet_item_label(item, :not_selected), :class => "facet_not_selected")
    end
  end

  def display_facet_items(facet, status)
    facet.items(status).collect { |i| display_facet_item(i) }.join("").html_safe
  end

  def facet_item_command(item, command)
    articles_search_path(@summon.search.query.to_hash.merge(item[:commands][command]))
  end
end
