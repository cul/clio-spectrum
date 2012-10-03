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
    template = options.delete(:template) || raise("Must specify template")
    formats = determine_formats(document, options.delete(:format))

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

  FORMAT_RANKINGS = ["ac", "database", "map_globe", "manuscript_archive", "video", "music_recording", "music", "newspaper", "serial", "book", "clio", "ebooks", "article", "summon", "lweb"]

  def format_online_results(urls)
    non_circ = image_tag("icons/noncirc.png", :class => :availability)
    urls.collect { |link| non_circ + link_to(process_online_title(link.first).abbreviate(80), link.last) }
  end

  def format_location_results(locations, document)
    locations.collect do |location|
    
      loc_display, hold_id = location.split('|DELIM|')
      clio_holding = "unknown"

      if document.get('clio_holdings') 
        status = document['clio_holdings']['statuses'][hold_id.to_s]
        clio_holding = status if status
      end

      image_tag("icons/#{clio_holding}.png", :class => "availability") + process_holdings_location(loc_display)
    end
  end

  def determine_formats(document, defaults = [])
    formats = defaults.listify
    formats << "ac" if @active_source == "Academic Commons"
    formats << "database" if @active_source == "Databases"
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

    formats.sort { |x,y| FORMAT_RANKINGS.index(x) <=> FORMAT_RANKINGS.index(y) }
  end

  # for segregating search values from display values
  DELIM = "|DELIM|"

  def generate_value_links(values, category)
    
    # display_value DELIM search_value [DELIM t880_flag]

    out = []

    values.listify.each do |v|
#    values.listify.select { |v| v.respond_to?(:split)}.each do |v|
      
      s = v.split(DELIM)
      
      unless s.length >= 2
        out << v
        next
      end

      # if displaying plain text, do not include links

      if @add_row_style == :text
        out << s[0]
      else
      
        case category
        when :all
          q = '"' + s[1] + '"'
          out << link_to(s[0], url_for(:controller => "catalog", :action => "index", :q => q, :search_field => "all_fields", :commit => "search"))
        when :author
          # s[2] is not nil when data is from an 880 field (vernacular)
          # temp workaround until we can get 880 authors into the author facet
          if s[2]
            # q = '"' + s[1] + '"'
            # out << link_to(s[0], url_for(:controller => "catalog", :action => "index", :q => q, :search_field => "author", :commit => "search"))
            out << s[0]
          else
            # remove puntuation from s[1] to match entries in author_facet using solrmarc removeTrailingPunc rule
            s[1] = s[1].gsub(/\.$/,'') if s[1] =~ /\w{3}\.$/ || s[1] =~ /[\]\)]\.$/
            out << link_to(s[0], url_for(:controller => "catalog", :action => "index", "f[author_facet][]" => s[1]))
          end
        when :subject
          out << link_to(s[0], url_for(:controller => "catalog", :action => "index", :q => s[1], :search_field => "subject", :commit => "search"))
        when :title
          q = '"' + s[1] + '"'
          out << link_to(s[0], url_for(:controller => "catalog", :action => "index", :q => q, :search_field => "title", :commit => "search"))
        else
          raise "invalid category specified for generate_value_links"
        end
      end
    end
    out
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
    options.reverse_merge!( {
      :display_blank => false,
      :display_only_first => false,
      :join => nil,
      :abbreviate => nil,
      :html_safe => true,
      :expand => false,
      :style => @add_row_style || :definition
    })

    value_txt = convert_values_to_text(value, options)


    result = ""
    if options[:display_blank] || !value_txt.empty?
      if options[:style] == :text
        result = (title.to_s + ": " + value_txt.to_s + "\r\n").html_safe
      else

        result = content_tag(:div, :class => "row") do
          if options[:style] == :definition
            content_tag(:div, title.to_s.html_safe, :class => "label") + content_tag(:div, content_tag(:div, value_txt, :class => "value_box"), :class => "value")
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

    values = values.collect(&:html_safe) if options[:html_safe]
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
      if options[:expand_to]
        pre_text += content_tag(:div, link_to(" more &#x25BC;".html_safe, "#"), :class => 'entry expander')
        pre_text += content_tag(:div, options[:expand_to].html_safe, :class => 'expander_more')
      end

      pre_text
    
    end


    value_txt = value_txt.html_safe if options[:html_safe]

    value_txt
  end  
end
