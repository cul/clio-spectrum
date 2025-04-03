module ArticlesHelper
  # EBOOKS_TO_LINK_FOLLOW = [
  #   'hdl.handle.net',
  #   'hathitrust.org'
  # ]

  # ----------------------------------------------------------------#
  # EDS-Specific version of the Summon-specific methods below
  # ----------------------------------------------------------------#

  def eds_get_article_authors(document)
    authors = ''
    return authors unless document.eds_authors

    # sometimes EDS returns redundante author names?
    authors_list = document.eds_authors.uniq
    
    # some articles have hundreds of authors - special handling...
    max_authors = 50
    authors = '  (more...)' if authors_list.count() > max_authors
    authors_list = authors_list.take(max_authors)
    
    # single string, comma-deliminted
    authors = authors_list.join(', ') + authors
    
    return authors
  end


  def eds_get_article_citation(document)
    results = []
    results << document.source_title.to_s if document.source_title
    results << document.eds_publication_date.to_s if document.eds_publication_date
    results << "ISSN: #{document.eds_issns.first}" unless document.eds_issns.empty?
    results << "Volume #{document.eds_volume}" if document.eds_volume
    results << "Issue #{document.eds_issue}" if document.eds_issue
    results << "p. #{document.eds_page_start}" if document.eds_page_start

    result = results.join(', ')
    result.empty? ? nil : result
  end

  def eds_get_article_type(document)
    type = document.eds_publication_type
    
    type += ': ' + eds_link_to_article(document, 'Citation Online')
    
    return type
  end

  # EDS documents can have several different kinds of links.
  # Which do we want to use?
  # For now, always return the link to "Full Text Finder"
  def eds_link_to_article(document, link_title = nil)
    link_title ||= document.title.html_safe
    
    document.eds_fulltext_links.each do |link|
      if link[:label] == 'Full Text Finder'
        return link_to(link_title, link[:url])
      end
    end
    
    # fallback if "Full Text Finder" not found?
    # return our proxied link to an ebscohost search
    return link_to(link_title, document.eds_plink) if document.eds_plink.present?
  end



  def eds_dump(document)
    all_fields = [
      :eds_accession_number,
      :eds_database_id,
      :eds_database_name,
      :eds_access_level,
      :eds_relevancy_score,
      :eds_title,
      :eds_source_title,
      :eds_composed_title,
      :eds_other_titles,
      :eds_abstract,
      :eds_authors,
      :eds_author_affiliations,
      :eds_authors_composed,
      :eds_subjects,
      :eds_subjects_geographic,
      :eds_subjects_person,
      :eds_subjects_company,
      :eds_subjects_mesh,
      :eds_subjects_bisac,
      :eds_subjects_genre,
      :eds_author_supplied_keywords,
      :eds_descriptors,
      :eds_notes,
      :eds_subset,
      :eds_languages,
      :eds_page_count,
      :eds_page_start,
      :eds_physical_description,
      :eds_publication_type,
      :eds_publication_type_id,
      :eds_publication_date,
      :eds_publication_year,
      :eds_publication_info,
      :eds_publication_status,
      :eds_publisher,
      :eds_document_type,
      :eds_document_doi,
      :eds_document_oclc,
      :eds_issn_print,
      :eds_issns,
      :eds_isbn_print,
      :eds_isbn_electronic,
      :eds_isbns_related,
      :eds_isbns,
      :eds_series,
      :eds_volume,
      :eds_issue,
      :eds_covers,
      :eds_cover_thumb_url,
      :eds_cover_medium_url,
      :eds_fulltext_word_count,
      :eds_result_id,
      :eds_plink,
      :eds_ebook_pdf_fulltext_available,
      :eds_ebook_epub_fulltext_available,
      :eds_pdf_fulltext_available,
      :eds_html_fulltext_available,
      :eds_html_fulltext,
      :eds_images,
      :eds_quick_view_images,
      :eds_all_links,
      :eds_fulltext_links,
      :eds_non_fulltext_links,
      :eds_code_naics,
      :eds_abstract_supplied_copyright,
      :eds_publication_id,
      :eds_publication_is_searchable,
      :eds_publication_scope_note,
      :eds_citation_exports,
      :eds_citation_styles
    ]
    
    dump = ''
    all_fields.each do |field|
      dump += add_row(field.to_s, document.send(field).to_s)
    end
    return dump
  end
    
  # ----------------------------------------------------------------#
  # Much of the below helper logic is Summon-specific.
  # Methods are replaced with "eds" specific methods (above) as needed.
  # ----------------------------------------------------------------#

  def link_to_article(article, link_title = nil)
    link_title ||= article.title.html_safe
    link_url = article.eds_plink
    # link_to(link_title, article.link)
    link_to(link_title, link_url)
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


  def eds_hidden_keys_for_search(query_as_hash)
    # based on Blacklight::HashAsHiddenFieldsHelperBehavior
    hidden_fields = []
    query_as_hash.each do |name, value|
      if value.is_a?(Array)
        value.each do |value_element|
          hidden_fields << hidden_field_tag("#{name}[]", value_element.to_json, id: nil)
        end
      else
        hidden_fields << hidden_field_tag(name, value.to_json, id: nil)
      end
      raise if name == 'f'
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
