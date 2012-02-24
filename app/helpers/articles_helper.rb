module ArticlesHelper
  def link_to_article(article, link_title = nil)
    link_title ||= article.title.html_safe
    if article.fulltext

      link_to link_title, articles_show_path(:openurl => article.src['openUrl'])
    else
      link_to link_title, URI.parse(article.url).to_s
    end
  end

  def get_article_type(doc)
    txt = doc.content_types.join(", ")
    if doc.fulltext
      txt += ": Full Text Available"
    elsif txt.include?("Journal Article")
      txt += ": Citation Online"
    end

    return txt
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

end
