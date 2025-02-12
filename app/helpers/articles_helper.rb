module ArticlesHelper
  # EBOOKS_TO_LINK_FOLLOW = [
  #   'hdl.handle.net',
  #   'hathitrust.org'
  # ]

  # ----------------------------------------------------------------#
  # EDS-Specific methods...
  # ----------------------------------------------------------------#

  def eds_link_to_article(article, link_title = nil)
    link_title ||= article.title.html_safe
    link_to(link_title, article.eds_plink)
  end

  def eds_get_article_citation(doc)
    results = []
    results << doc.source_title.to_s if doc.source_title
    results << doc.eds_publication_date.to_s if doc.eds_publication_date
    results << "ISSN: #{doc.eds_issns.first}" unless doc.eds_issns.empty?
    results << "Volume #{doc.eds_volume}" if doc.eds_volume
    results << "Issue #{doc.eds_issue}" if doc.eds_issue
    results << "p. #{doc.eds_page_start}" if doc.eds_page_start

    result = results.join(', ')
    result.empty? ? nil : result
  end

  # ----------------------------------------------------------------#
  # Much of the below helper logic is Summon-specific.
  # Methods are replaced with "eds" specific methods as needed.
  # ----------------------------------------------------------------#

  def link_to_article(article, link_title = nil)
    link_title ||= article.title.html_safe
    link_to(link_title, article.link)
  end

  def get_article_type(doc)
    txt = doc.content_types.join(', ')

    if doc.fulltext
      txt += if is_music?(doc) || doc.content_types.include?('Reference')
               ': ' + link_to_article(doc, 'Available Online')
             else
               ': ' + link_to_article(doc, 'Full Text Available')
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
    results << doc.publication_title.to_s if doc.publication_title
    results << process_summon_date(doc.publication_date).to_s if doc.publication_date
    results << "ISSN: #{doc.issns.first}" unless doc.issns.empty?
    results << "Volume #{doc.volume}" if doc.volume
    results << "Issue #{doc.issue}" if doc.issue
    results << "p. #{doc.start_page}" if doc.start_page

    result = results.join(', ')
    result.empty? ? nil : result
  end

  def get_article_authors(document)
    return '' unless document.src && document.src['Author_xml']
    ordered_authors = []
    authors_to_show = 50 # some articles have hundreds of authors - only show first N
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
      authors_display += '  (more...)'
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
      value = 1 if name == 's.pn'

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
      Array.wrap(summon_query_as_hash['s.fq']).each do |fq|
        field, value = fq.split(':')
        # Summon text filter queries are wrapped in parens
        # to be literal matches.  Undo for BL user input fields.
        value = value.sub(/^\((.+)\)$/, '\1')
        # Rails.logger.debug "field/value=#{field}/#{value}"
        hash[field] = value
      end
    end

    hash
  end

  def iso2american(range)
    return ['', ''] if range.blank?
    min = iso2american_single_date(range.min_value)
    max = iso2american_single_date(range.max_value)
    [min, max]
  end

  # Inverse of SpectrumController#parse_single_dates
  # turn summon's internal date format back into
  # american display date format MM/DD/YYYY
  def iso2american_single_date(date)
    return '' if date.blank?
    return date if date =~ /^\d+$/

    parts = date.split('-')
    # 1999-12 --> 12/1999
    return [parts[1], parts[0]].join('/') if parts.size == 2
    # 1999-12-20 --> 12/20/1999
    return [parts[1], parts[2], parts[0]].join('/') if parts.size == 3
  end
end
