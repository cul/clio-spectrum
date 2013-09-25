# encoding: utf-8

module DisplayHelper

  def render_first_available_partial(partials, options)
    partials.each do |partial|
      begin
        return render(:partial => partial, :locals => options)
      rescue ActionView::MissingTemplate
        next
      end
    end

    raise "No partials found from #{partials.inspect}"

  end

  FORMAT_MAPPINGS = {
    "Book" => "book",
    "Online" =>"link",
    "Computer File" => "computer-file",
    "Sound Recording" => "non-musical-recording",
    "Music - Score" => "musical-score",
    "Music - Recording" => "musical-recording",
    "Thesis" => "thesis",
    "Microformat" => "microform",
    "Journal/Periodical" => "journal",
    "Conference Proceedings" => "conference",
    "Video" => "video",
    "Map/Globe" => "map-or-globe",
    "Manuscript/Archive" => "manuscript",
    "Newspaper" => "newspaper",
    "Database" => "database",
    "Image" => "image"
  }


  def formats_with_icons(document)
    document['format'].listify.collect do |format|
      if (icon = FORMAT_MAPPINGS[format]) && @add_row_style != :text
        image_tag("icons/#{icon}.png", :size => "16x16") + " #{format}"
      else
        format.to_s
      end
    end.join(", ").html_safe
  end

  def render_documents(documents, options)
    partial = "/_display/#{options[:action]}/#{options[:view_style]}"
    render partial, { :documents => documents.listify}

  end

  def render_document_view(document, options = {})
    options.symbolize_keys!
    template = options.delete(:template) || raise("Must specify template")
    formats = determine_formats(document, options.delete(:format))

    # Render based on @active_source -- unless an alternative is passed in
    options[:source] ||= @active_source

    partial_list = formats.collect { |format| "/_formats/#{format}/#{template}"}
    @add_row_style = options[:style]
    view = render_first_available_partial(partial_list, options.merge(:document => document))
    @add_row_style = nil

    return view
  end

  SOLR_FORMAT_LIST = {
    "Music - Recording" => "music_recording",
    "Music - Score" => "music",
    "Journal/Periodical" => "serial",
    "Manuscript/Archive" => "manuscript_archive",
    "Newspaper" => "newspaper",
    "Video" => "video",
    "Map/Globe" => "map_globe",
    "Book" => "book"
  }

  SUMMON_FORMAT_LIST = {
    "Book" => "ebooks",
    "Journal Article" => "article"
  }

  FORMAT_RANKINGS = ["ac", "database", "map_globe", "manuscript_archive", "video", "music_recording", "music", "newspaper", "serial", "book", "clio", "ebooks", "article", "articles", "summon", "lweb"]

  def format_online_results(urls)
    non_circ = image_tag("icons/noncirc.png", :class => :availability)
    urls.collect { |link|
      non_circ +
      link_to(process_online_title(link[:title]).abbreviate(80), link[:url]) +
      content_tag(:span, link[:note], class: 'url_link_note')
    }
  end

  def format_location_results(locations, document)
    locations.collect do |location|

      loc_display, hold_id = location.split('|DELIM|')
      clio_holding = "unknown"

      if document.get('clio_holdings')
        status = document['clio_holdings']['statuses'][hold_id.to_s]
        clio_holding = status if status
      end

      image_tag("icons/#{clio_holding}.png", :class => "availability holding_#{hold_id}") + process_holdings_location(loc_display)
    end
  end

  def determine_formats(document, defaults = [])
    formats = defaults.listify
    formats << "ac" if @active_source == "academic_commons"
    formats << "database" if @active_source == "databases"
    case document
    when SolrDocument
      formats << "clio"

      document["format"].listify.each do |format|
        formats << SOLR_FORMAT_LIST[format] if SOLR_FORMAT_LIST[format]
      end
    when Summon::Document
      formats << "summon"
      document.content_types.each do |format|
        formats << SUMMON_FORMAT_LIST[format] if SUMMON_FORMAT_LIST[format]
      end
    when SerialSolutions::Link360
      formats << "summon"
    end

    begin
      formats.sort { |x,y| FORMAT_RANKINGS.index(x) <=> FORMAT_RANKINGS.index(y) }
    rescue
      raise formats.inspect
    end
  end

  # for segregating search values from display values
  DELIM = "|DELIM|"

  def generate_value_links(values, category)

    # display_value DELIM search_value [DELIM t880_flag]

    out = []

    values.listify.each do |v|
#    values.listify.select { |v| v.respond_to?(:split)}.each do |v|

      # s = v.split(DELIM)
      display_value, search_value, t880_indicator = v.split(DELIM)

      # the display value has already been made html-escaped by MarcHelper.
      # mark it as html-safe to avoid double-encoding
      display_value = display_value.html_safe

      # no link value
      # unless s.length >= 2
      unless search_value
        out << v
        next
      end

      # if displaying plain text, do not include links

      if @add_row_style == :text
        # out << s[0]
        out << display_value
      else

        case category
        when :all
          # q = '"' + s[1] + '"'
          # out << link_to(s[0], url_for(:controller => "catalog", :action => "index", :q => q, :search_field => "all_fields", :commit => "search"))
          q = '"' + search_value + '"'
          out << link_to(display_value, url_for(:controller => "catalog", :action => "index", :q => q, :search_field => "all_fields", :commit => "search"))
        when :author
          # s[2] is not nil when data is from an 880 field (vernacular)
          # temp workaround until we can get 880 authors into the author facet
          # if s[2]
          if t880_indicator
            # q = '"' + s[1] + '"'
            # out << link_to(s[0], url_for(:controller => "catalog", :action => "index", :q => q, :search_field => "author", :commit => "search"))
            # out << s[0]
            out << display_value

          else
            # remove puntuation from s[1] to match entries in author_facet using solrmarc removeTrailingPunc rule
#            s[1] = s[1].gsub(/\.$/,'') if s[1] =~ /\w{3}\.$/ || s[1] =~ /[\]\)]\.$/
#            s[1] = s[1].gsub(/,$/,'')
# s[1] = remove_punctuation(s[1])
            search_value = remove_punctuation(search_value)

            # out << link_to(s[0].html_safe, url_for(:controller => "catalog", :action => "index", "f[author_facet][]" => s[1]))
            out << link_to(display_value, url_for(:controller => "catalog", :action => "index", "f[author_facet][]" => search_value))
          end
        when :subject
          # out << link_to(s[0], url_for(:controller => "catalog", :action => "index", :q => s[1], :search_field => "subject", :commit => "search"))
          out << link_to(display_value, url_for(:controller => "catalog", :action => "index", :q => search_value, :search_field => "subject", :commit => "search"))
        when :title
          # q = '"' + s[1] + '"'
          # out << link_to(s[0], url_for(:controller => "catalog", :action => "index", :q => q, :search_field => "title", :commit => "search"))
          q = '"' + search_value + '"'
          out << link_to(display_value, url_for(:controller => "catalog", :action => "index", :q => q, :search_field => "title", :commit => "search"))
        else
          raise "invalid category specified for generate_value_links"
        end
      end
    end
    out
  end

  def remove_punctuation(value)

    # matches edit from SolrMARC removeTrailingPunc method: Utils.cleanData
    #
    # Removes trailing characters (space, comma, slash, semicolon, colon) and
    #  trailing period if it is preceded by at least three (two?) letters

    curr = value
    prev = ''

    while curr != prev
      prev = curr
      curr = curr.strip

      curr = curr.gsub(/\s*[,\/;:]$/,'')

      if curr =~ /\.$/
        if curr =~ /[JS]r\.$/
          # don't strip period off Jr. or Sr.
        elsif curr =~ /\w\w\.$/
          curr = curr.chop
        elsif curr =~ /\p{L}\p{L}\.$/
          curr = curr.chop
          # IsCombiningDiacriticalMarks is not supported in Ruby; using weaker formulation
          # elsif curr =~ /\w\p{IsCombiningDiacriticalMarks}?\w\p{IsCombiningDiacriticalMarks}?\.$/
          #  curr = curr.chop
        elsif curr =~ /\w[^a-zA-Z0-9 ]?\w[^a-zA-Z0-9 ]?\.$/
          curr = curr.chop
        elsif curr =~ /\p{Punct}\.$/
          curr = curr.chop
        end
      end

    end

    curr

  end

  # def generate_value_links_subject(values)
  #
  #   # search value the same as the display value
  #   # quote first term of the search string and remove ' - '
  #
  #   values.listify.collect do |v|
  #
  #     sub = v.split(" - ")
  #     out = '"' + sub.shift + '"'
  #     out += ' ' + sub.join(" ") unless sub.empty?
  #
  #     link_to(v, url_for(:controller => "catalog", :action => "index", :q => out, :search_field => "subject", :commit => "search"))
  #
  #   end
  # end

  def generate_value_links_subject(values)

    # search value the same as the display value
    # but chained to create a series of searches that is increasingly narrower
    # esample: a - b - c
    # link display   search
    #   a             "a"
    #   b             "a b"
    #   c             "a b c"

    values.listify.collect do |value|
#    values.listify.select { |x| x.respond_to?(:split)}.collect do |value|

      searches = []
      subheads = value.split(" - ")
      first = subheads.shift
      display = first
      search = first
      title = first

      searches << build_subject_url(display, search, title)

      unless subheads.empty?
        subheads.each do |subhead|
          display = subhead
          search += ' ' + subhead
          title += ' - ' + subhead
          searches << build_subject_url(display, search, title)
        end
      end

      if @add_row_style == :text
        searches.join(' - ')
      else
        searches.join(' > ')
      end

    end
  end

  def build_subject_url(display, search, title)

    display = display.html_safe

    search = CGI::unescapeHTML(search)

    if @add_row_style == :text
      display
    else
      link_to(display, url_for(:controller => "catalog",
                              :action => "index",
                              :q => '"' + search + '"',
                              :search_field => "subject",
                              :commit => "search"),
                              :title => title)
    end
  end

  def add_row(title, value, options = {})
    options.reverse_merge!(@add_row_options) if @add_row_options.kind_of?(Hash)
    options.reverse_merge!( {
      :display_blank => false,
      :display_only_first => false,
      :join => nil,
      :abbreviate => nil,
      :html_safe => true,
      :expand => false,
      :style => @add_row_style || :definition,
      :spans => [2,10]
    })


    value_txt = convert_values_to_text(value, options)
    spans = options[:spans]


    result = ""
    if options[:display_blank] || !value_txt.empty?
      if options[:style] == :text
        Rails.logger.debug "options=#{options.inspect}"
        Rails.logger.debug "title/value_txt=#{title.inspect}/#{value_txt.inspect}"
        result = (title.to_s + ": " + value_txt.to_s + "\r\n").html_safe
      else

        result = content_tag(:div, :class => "document-row") do
          if options[:style] == :definition
            content_tag(:div, title.to_s.html_safe, :class => "field span#{spans.first}") + content_tag(:div, content_tag(:div, value_txt, :class => "value_box"), :class => "value span#{spans.last}")
          elsif options[:style] == :blockquote
            content_tag(:div, content_tag(:div, value_txt, :class => "value_box"), :class => "blockquote")
          end
        end
      end

    end

    result
  end

  def convert_values_to_text(value, options = {})

    values = value.listify

    values = values.collect { |txt| txt.to_s.abbreviate(options[:abbreviate]) } if options[:abbreviate]

    if options[:html_safe]
      values = values.collect(&:html_safe)
    else
      values = values.collect { |v| h(v) }.collect(&:html_safe)
    end
    values = if options[:display_only_first]
      values.first.to_s.listify
    elsif options[:join]
      values.join(options[:join]).to_s.listify.reject { |item| item.to_s.empty? }
    else
      values
    end

    value_txt = if options[:style] == :text
      values.join("\r\n  ")
    else
      pre_values = values.collect { |v| content_tag(:div, v, :class => 'entry') }

      if options[:expand] && values.length > 3
        pre_values = [
          pre_values[0],
          pre_values[1],
          content_tag(:div, link_to("#{values.length - 2} more &#x25BC;".html_safe, "#"), :class => 'entry expander'),
          content_tag(:div, pre_values[2..-1].join('').html_safe, :class => 'expander_more')
        ]

      end

      pre_text = pre_values.join('')
      if options[:expand_to] && ! options[:expand_to].strip.empty?
        pre_text += content_tag(:div, link_to(" more &#x25BC;".html_safe, "#"),
                                :class => 'entry expander')
        pre_text += content_tag(:div, options[:expand_to].html_safe,
                                :class => 'expander_more')
      end

      pre_text

    end

    value_txt = value_txt.html_safe
    value_txt
  end

  # Exports CUL Catalog SolrDocument as an OpenURL KEV
  # (key-encoded value) query string.
  # For use to create COinS, among other things. COinS are
  # for Zotero, among other things.
  def catalog_to_openurl_ctx_kev(document)
    return '' unless document
    format = document[:format].first ||= 'book'

    fields = []
    fields.push( 'ctx_ver=Z39.88-2004' )

    document[ :author_display ] && document[ :author_display ].each do |author|
      fields.push("rft.au=#{ CGI::escape(author) }")
    end

    document[ :title_display ] && document[ :title_display ].each do |title|
      fields.push("rft.title=#{ CGI::escape(title) }")
    end

    document[ :full_publisher_display ] && document[ :full_publisher_display ].each do |publisher|
      fields.push("rft.pub=#{ CGI::escape(publisher) }")
    end

    document[ :pub_date_facet ] && document[ :pub_date_facet ].each do |pub_date_facet|
      fields.push("rft.date=#{ CGI::escape(pub_date_facet) }")
    end

    document[ :isbn_display ] && document[ :isbn_display ].each do |isbn|
      fields.push("rft.isbn=#{ CGI::escape(isbn) }")
    end

    if format =~ /journal/i
      # JOURNAL-SPECIFIC FIELDS
      fields.push( 'rft_val_fmt=info:ofi/fmt:kev:mtx:journal')
      # title is redundantly given as "atitle" for books
      document[ :title_display ] && document[ :title_display ].each do |title|
        fields.push("rft.atitle=#{ CGI::escape(title) }")
      end
    else
      # BOOK-SPECIFIC FIELDS
      fields.push( 'rft_val_fmt=info:ofi/fmt:kev:mtx:book')
      # title is redundantly given as "btitle" for books
      document[ :title_display ] && document[ :title_display ].each do |title|
        fields.push("rft.btitle=#{ CGI::escape(title) }")
      end
    end

    fields.push("rft.genre=#{ CGI::escape(format_to_rft_genre(format)) }")


    return fields.join('&')
  end

  def format_to_rft_genre (format)
    case format
    when /journal/i
      'article'
    when /book/i
      'book'
    when /proceeding/i
      'proceeding'
    when /conference/i
      'conference'
    when /report/i
      'report'
    else
      # http://ocoins.info/cobgbook.html
      # "general document type to be used when available data elements
      #  do not allow determination of a more specific document type"
      'document'
    end
  end

  # Exports CUL Academic Commons SolrDocument as an OpenURL KEV
  # (key-encoded value) query string.
  # For use to create COinS, among other things. COinS are
  # for Zotero, among other things.
  def ac_to_openurl_ctx_kev(document)
    fields = []

    fields.push( 'ctx_ver=Z39.88-2004' )
    fields.push( 'rft_val_fmt=info:ofi/fmt:kev:mtx:journal')

    # Many fields used to be arrays on katana, but on macana appear to be strings?
    # Defend ourselves by using Array.wrap() on everything.

    Array.wrap(document[ :id ]).each do |id|
      document_url= 'http://academiccommons.columbia.edu/catalog/' + id
      fields.push("rft_id=#{ CGI::escape(document_url) }")
    end

    document[ :author_facet ] && Array.wrap(document[ :author_facet ]).each do |author|
      fields.push("rft.au=#{ CGI::escape(author) }")
    end

    document[ :title_display ] && Array.wrap(document[ :title_display ]).each do |title|
      fields.push("rft.atitle=#{ CGI::escape(title) }")
    end

    document[ :publisher ] && Array.wrap(document[ :publisher ]).each do |publisher|
      fields.push("rft.pub=#{ CGI::escape(publisher) }")
    end

    document[ :pub_date_facet ] && Array.wrap(document[ :pub_date_facet ]).each do |pub_date_facet|
      fields.push("rft.date=#{ CGI::escape(pub_date_facet) }")
    end

    return fields.join('&')
  end

end
