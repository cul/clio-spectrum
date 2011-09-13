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
end
