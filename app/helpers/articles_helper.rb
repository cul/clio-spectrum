module ArticlesHelper
  EBOOKS_TO_LINK_FOLLOW = [
    'hdl.handle.net',
    'hathitrust.org'
  ]

  def link_to_article(article, link_title = nil)
    link_title ||= article.title.html_safe
    link_to(link_title, article.link)

    # OLD CODE - back from when we had articles item-detail pages?
    # url = ''
    # # If the article is a fulltext Journal Article, Book, or eBook...
    # if article.fulltext &&
    #    !(article.content_types & ['Journal Article','Book', 'eBook']).empty?
    #   # If the article is an eBook and it's URL is to handle.net or hathi...
    #   if article.content_types.include?('eBook') &&
    #      EBOOKS_TO_LINK_FOLLOW.any? { |eb| article.uri.to_s.include?(eb) }
    #     url = article.link
    #   else
    #     url = articles_show_path(:openurl => article.src['openUrl'])
    #   end
    # else
    #   url = article.link
    # end
    #
    # link_to link_title, url
  end

# OLD CODE - nothing calls this
  # def generate_ill_link(document)
  #   base = "https://www1.columbia.edu/sec-cgi-bin/cul/illiad/testref360?"
  #   epage = params['openurl'].to_s.scan(/rft.epage.(\d+)/)
  #   epage = epage && epage.first && epage.first.first ? epage.first.first : ""
  #   issns = document.issns
  #   issn = issns && issns.first ? issns.first[:value].to_s : ""
  #   link_params = {
  #     'Volume' => document.volume,
  #     'Issue' => document.issue,
  #     'Source' => 'info:sid/summon.serialssolutions.com (Via CLIO)',
  #     'Author' => document.creator,
  #     'Article' => document.title,
  #     'Genre' => 'article',
  #     'Pages' => "#{document.spage}-#{epage}",
  #     'Journal' => document.source,
  #     'LoanTitle' => document.source,
  #     'Date' => document.date,
  #     'ISSN' => issn
  #   }
  #
  #  (base + link_params.to_query).html_safe
  # end

  # No longer used - this was for the old partials,
  # working against the Articles Controller
  #
  # ARTICLE_HOLDING_ICONS = {
  #   'book' => 'icons/book.png',
  #   'article' => 'icons/article.png',
  #   'journal' => 'icons/journal.png',
  #   'source' => 'icons/database.png',
  #   'volume' => 'icons/volume.png'
  # }
  #
  # ARTICLE_HOLDING_NAMES = {
  # }
  #
  # ARTICLE_HOLDING_LINK_ORDER = %w{book article journal volume source}
  #
  # def display_article_holdings_links(holding)
  #   holding[:urls].keys.reject { |key|
  #     key == 'issue'
  #   }.sort_by { |key|
  #     ARTICLE_HOLDING_LINK_ORDER.index(key)
  #   }.collect { |source|
  #     url = holding[:urls][source]
  #     title = ARTICLE_HOLDING_NAMES[source] || source.humanize
  #     icon = ARTICLE_HOLDING_ICONS[source]
  #     title = content_tag(:span, "#{image_tag(icon)} ".html_safe + title,
  #                         :class => "article_holding").html_safe if icon
  #
  #     link_to(title, url, :target => "_blank")
  #   }.join("").html_safe
  #
  # end

  def get_article_type(doc)
    txt = doc.content_types.join(', ')

    if doc.fulltext
      if is_music?(doc) || doc.content_types.include?('Reference')
        txt += ': ' + link_to_article(doc, 'Available Online')
      else
        txt += ': ' + link_to_article(doc, 'Full Text Available')
      end
    # elsif txt.include?("Journal Article")
    else
      txt += ': ' + link_to_article(doc, 'Citation Online')
    end

    txt
  end

  def is_music?(doc)
    !(doc.content_types & ['Audio Recording', 'Music Recording']).empty?
  end

  def get_article_citation(doc)
    results = []
    results <<  "#{doc.publication_title}"  if doc.publication_title
    results << "#{process_summon_date(doc.publication_date)}" if doc.publication_date
    results << "ISSN: #{doc.issns.first}" unless doc.issns.empty?
    results << "Volume #{doc.volume.to_s}" if doc.volume
    results << "Issue #{doc.issue}" if doc.issue
    results << "p. #{doc.start_page}" if doc.start_page

    result = results.join(', ')
    result.empty? ? nil : result
  end

  def get_article_authors(document)
    return '' unless document.src and document.src['Author_xml']
    ordered_authors = []
    authors_to_show = 50  # some articles have hundreds of authors - only show first N
    total_authors = document.src['Author_xml'].size
    document.src['Author_xml'].each do |author|
      ordered_authors.push author['fullname']
      break if ordered_authors.size >= authors_to_show
    end
    authors_display = ordered_authors.join ', '
    if total_authors >= authors_to_show
      # 1/2014 - the Summon API (and native interface!) have changed, to only return
      # the first 100 authors.  So we no longer have an accurate "total_authors" count.
      # authors_display +=  "  (additional #{total_authors - authors_to_show} authors not shown)"
      authors_display +=  '  (more...)'
    end
    authors_display
  end

  def process_summon_date(date)
    # NEXT-598 - Articles date formatting - use MM/DD/YYYY
    [date.month, date.day, date.year].compact.join('/')
  end

  def summon_hidden_keys_for_search(summon_query_as_hash)
    # based on Blacklight::HashAsHiddenFieldsHelperBehavior
    hidden_fields = []
    summon_query_as_hash.each do |name, value|

      # NEXT-903 - ALWAYS reset to page #1 whenever a summon search is submitted
      if name == 's.pn'
        value = 1
      end

      # this is moved to the caller's responsibility
      # # skip the advanced search fields, we're sending them in un-hidden
      # next if name == 's.fq'

      if value.is_a?(Array)
        value.each do |value_element|
          hidden_fields << hidden_field_tag("#{name}[]", value_element.to_s, id: nil)
        end
      else
        hidden_fields << hidden_field_tag(name, value.to_s, id: nil)
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
  # ### ### This is based on CGI Params... but those are unrelible, as they
  # ### ### dont' factor in constraint "Remove" commands.
  # def build_articles_advanced_field_values_hash(params)
  #   hash = {}
  #
  #   if params['s.fq']
  #     params['s.fq'].each do |field, value|
  #       # Rails.logger.debug "field/value=#{field}/#{value}"
  #       hash[field] = value
  #     end
  #   end
  #
  #   # For:
  #   #   "q"=>"nature"
  #   #   "search_field"=>"s.fq[PublicationTitle]"
  #   # Set:
  #   # 's.fq[PublicationTitle]' => 'nature'
  #   if /s.fq\[(\w+)\]/ =~ params['search_field']
  #     hash[$1] = params['q']
  #   end
  #   hash
  # end

  # - field_values = build_articles_advanced_field_values_hash(summon_query_as_hash)
  def build_articles_advanced_field_values_hash(summon_query_as_hash)
    hash = {}
# raise
    if summon_query_as_hash['s.q']
      # hash['s.q'] = summon_query_as_hash['s.q']
      hash['q'] = summon_query_as_hash['s.q']
    end

    if summon_query_as_hash['s.fq']
      Array.wrap(summon_query_as_hash['s.fq']).each do | fq |
        field, value = fq.split(':')
        # Rails.logger.debug "field/value=#{field}/#{value}"
        hash[field] = value
      end
    end

    hash
  end
end
