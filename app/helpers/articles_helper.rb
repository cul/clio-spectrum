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

  def display_facet_label(item, value = :not_selected)
    label = item[:label].to_s
    label = "NOT " + label if value == :negated
    label += " (#{number_with_delimiter(item[:count], :delimiter => ".")})" if value == :not_selected
    content_tag(:span, "#{label}", :class => 'facet_label')
  end
  
  def display_selected_facet(item)

    content_tag(:li, image_tag("icons/facet_cancel.png",  :class => "facet_cancel facet_action", :size => "14x14", :href => facet_command(item, :remove)) + display_facet_label(item, :selected), :class => "facet_selected")

  end

  def display_negated_facet(item)

    content_tag(:li, image_tag("icons/facet_cancel.png", :class => "facet_cancel facet_action", :size => "14x14", :href => facet_command(item, :remove)) + display_facet_label(item, :negated), :class => "facet_negated")

  end
  def display_not_selected_facet(item)

    content_tag(:li, 
                image_tag("icons/facet_plus.png", :class => "facet_plus facet_action", :size => "14x14", :href => facet_command(item, :select)) + 
                image_tag("icons/facet_minus.png", :class => "facet_minus facet_action", :size => "14x14", :href => facet_command(item, :negate)) + 
                display_facet_label(item, :not_selected), :class => "facet_not_selected")
  end

  def facet_command(item, command)
    article_search_path(@search.query.to_hash.merge(item[:commands][command]))
  end
end
