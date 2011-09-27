module ArticlesHelper
  def link_to_article(article, link_title = nil)
    link_title ||= article.title.html_safe
    link_to link_title, article_show_path(:openurl => article.src['openUrl'])
  end

  def get_article_citation(doc)
    results = []
    results <<  "#{doc.publication_title}"  if doc.publication_title
    results << "#{process_summon_date(doc.publication_date)}" if doc.publication_date
    results << "ISSN: #{doc.issns.first}" unless doc.issns.empty?
    results << "Volume #{doc.volume.to_s}" if doc.volume
    results << "Issue #{doc.issue}" if doc.issue
    results << "p. #{doc.start_page}" if doc.start_page 

    result = results.join(", ") 
    result.empty? ? nil : result
  end

  def process_summon_date(date)
    [date.day, date.month, date.year].compact.join("/")
  end

  def facet_check_box(facet, item)
    value = item.applied?
    command = item.applied? ? item.remove_command : item.apply_command
    check_box_tag("facet:#{item.value.underscore}", 'selected', value, :class => "facet_toggle", :href => url_with_command(command))
  end

  def url_with_command(command)
    article_search_path(@search.query.to_hash.merge('s.cmd' => command))
  end

  def display_facet_label(item)
    content_tag(:span, "#{item[:label]} (#{number_with_delimiter(item[:count], :delimiter => ".")})", :class => 'facet_label')
  end
  
  def display_selected_facet(item)

    content_tag(:li, image_tag("icons/facet_plus.png", :class => "facet_plus", :size => "14x14", :href => facet_deselect_command) + display_facet_label(item))

  end

  def display_not_selected_facet(item)

    content_tag(:li, 
                image_tag("icons/facet_plus.png", :class => "facet_plus facet_action", :size => "14x14", :href => facet_deselect_command) + 
                image_tag("icons/facet_minus.png", :class => "facet_minus facet_action", :size => "14x14", :href => facet_deselect_command) + 
                display_facet_label(item))
  end

  def facet_deselect_command
  end
end
