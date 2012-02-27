module ArticlesHelper
  def link_to_article(article, link_title = nil)
    link_title ||= article.title.html_safe
    
    url = ""
    
    if article.fulltext
      #if article.content_types.include?("Audio Recording")
      if is_music?(article)
        url = URI.parse(article.url).to_s
      else
        url = articles_show_path(:openurl => article.src['openUrl'])
      end
    else
      url = URI.parse(article.url).to_s
    end

    link_to link_title, url
  end


  ARTICLE_HOLDING_ICONS = {
    'book' => 'icons/book.png',
    'article' => 'icons/article.png',
    'journal' => 'icons/journal.png',
    'source' => 'icons/database.png'
  }

  def display_article_holdings_links(holding)
    holding[:urls].keys.sort.collect do |source|
      url = holding[:urls][source]
      title = source.humanize
      icon = ARTICLE_HOLDING_ICONS[source]
      title = "#{image_tag(icon)} ".html_safe + title if icon

      link_to(title, url)
    end.join("").html_safe
    
  end

  def get_article_type(doc)
    txt = doc.content_types.join(", ")
    
    if doc.fulltext
      if is_music?(doc)
        txt += ": " + link_to_article(doc, "Available Online")
      else
        txt += ": " + link_to_article(doc, "Full Text Available")
      end
    elsif txt.include?("Journal Article")
      txt += ": " + link_to_article(doc, "Citation Online")
    end

    return txt
  end

  def is_music?(doc)
    !(doc.content_types & ["Audio Recording", "Music Recording"]).empty?
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
