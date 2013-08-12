module ArticlesHelper
  EBOOKS_TO_LINK_FOLLOW = [
    'hdl.handle.net',
    'hathitrust.org'
  ]

  def link_to_article(article, link_title = nil)

    link_title ||= article.title.html_safe
    return link_to(link_title, article.link)

    url = ''
    # If the article is a fulltext Journal Article, Book, or eBook...
    if article.fulltext &&
       !(article.content_types & ['Journal Article','Book', 'eBook']).empty?
      # If the article is an eBook and it's URL is to handle.net or hathi... 
      if article.content_types.include?('eBook') &&
         EBOOKS_TO_LINK_FOLLOW.any? { |eb| article.uri.to_s.include?(eb) }
        url = article.link
      else
        url = articles_show_path(:openurl => article.src['openUrl'])
      end
    else
      url = article.link
    end


    link_to link_title, url
  end




  def generate_ill_link(document)
    base = "https://www1.columbia.edu/sec-cgi-bin/cul/illiad/testref360?"
    epage = params['openurl'].to_s.scan(/rft.epage.(\d+)/)
    epage = epage && epage.first && epage.first.first ? epage.first.first : ""
    issn = document.issns && document.issns.first ? document.issns.first[:value].to_s : ""
    link_params = {
      'Volume' => document.volume,
      'Issue' => document.issue,
      'Source' => 'info:sid/summon.serialssolutions.com (Via CLIO)',
      'Author' => document.creator,
      'Article' => document.title,
      'Genre' => 'article',
      'Pages' => "#{document.spage}-#{epage}",
      'Journal' => document.source,
      'LoanTitle' => document.source,
      'Date' => document.date,
      'ISSN' => issn
    }

   (base + link_params.to_query).html_safe

  end

  ARTICLE_HOLDING_ICONS = {
    'book' => 'icons/book.png',
    'article' => 'icons/article.png',
    'journal' => 'icons/journal.png',
    'source' => 'icons/database.png',
    'volume' => 'icons/volume.png'
  }

  ARTICLE_HOLDING_NAMES = {
  }

  ARTICLE_HOLDING_LINK_ORDER = %w{book article journal volume source}

  def display_article_holdings_links(holding)
    holding[:urls].keys.reject { |k| k == 'issue' }.sort_by { |x| ARTICLE_HOLDING_LINK_ORDER.index(x) }.collect do |source|
      url = holding[:urls][source]
      title = ARTICLE_HOLDING_NAMES[source] || source.humanize
      icon = ARTICLE_HOLDING_ICONS[source]
      title = content_tag(:span, "#{image_tag(icon)} ".html_safe + title, :class => "article_holding").html_safe if icon

      link_to(title, url, :target => "_blank")
    end.join("").html_safe

  end

  def get_article_type(doc)
    txt = doc.content_types.join(", ")

    if doc.fulltext
      if is_music?(doc) || doc.content_types.include?("Reference")
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

  def get_article_authors(document)
    return '' unless document.src and document.src['Author_xml']
    ordered_authors = []
    authors_to_show = 100  # some articles have hundreds of authors - only show first N
    total_authors = document.src['Author_xml'].size
    document.src['Author_xml'].each { |author|
      ordered_authors.push author['fullname']
      break if ordered_authors.size >= authors_to_show
    }

    ordered_authors = ordered_authors.join ', '
    if ordered_authors.size >= authors_to_show
      ordered_authors +=  "  (additional #{total_authors - authors_to_show} authors not shown)"
    end

  end

  def process_summon_date(date)
    # NEXT-598 - Articles date formatting - use MM/DD/YYYY
    [date.month, date.day, date.year].compact.join("/")
  end


  def summon_hidden_keys_for_search(summon_query_as_hash)
    # based on Blacklight::HashAsHiddenFieldsHelperBehavior
    hidden_fields = []
    summon_query_as_hash.each do |name, value|

      # this is moved to the caller's responsibility
      # # skip the advanced search fields, we're sending them in un-hidden
      # next if name == 's.fq'

      if value.is_a?(Array)
        value.each do |v|
          hidden_fields << hidden_field_tag("#{name}[]", v.to_s, :id => nil)
        end
      else
        hidden_fields << hidden_field_tag(name, value.to_s, :id => nil)
      end

      # value = [value] if !value.is_a?(Array)
      # value.each do |v|
      #   hidden_fields << hidden_field_tag(name, v.to_s, :id => nil)
      # end
    end

    hidden_fields.join("\n").html_safe
  end


  #  SIMPLE SEARCH:
  #   "q"=>"nature"
  #   "search_field"=>"s.fq[PublicationTitle]"
  #   "s.q"=>""
  #  ADVANCED SEARCH:
  #  search_field=advanced
  #   "s.q"=>""
  #   "s.fq"=>{"AuthorCombined"=>"", "TitleCombined"=>"", 
  #            "PublicationTitle"=>"nature", "ISBN"=>"", "ISSN"=>""}
  def build_articles_advanced_field_values_hash(params)
    hash = {}

    if params['s.fq']
      params['s.fq'].each do |field, value|
        # Rails.logger.debug "field/value=#{field}/#{value}"
        hash[field] = value
      end
    end

    if /s.fq\[(\w+)\]/ =~ params['search_field']
      hash[$1] = params['q']
    end
    hash
  end

end
