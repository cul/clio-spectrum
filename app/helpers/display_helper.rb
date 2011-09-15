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
      if (icon = FORMAT_MAPPINGS[format])
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
    render_first_available_partial(partial_list, options.merge(:document => document))


  end 

  SOLR_FORMAT_LIST = {
    "Music - Recording" => "music_recording",
    "Music - Score" => "music"
  }

  SUMMON_FORMAT_LIST = {
    "Book" => "ebooks",
    "Journal Article" => "article"
  }

  FORMAT_RANKINGS = ["music_recording", "music", "clio", "ebooks", "article","summon", "lweb"]

  def determine_formats(document, defaults = [])
    formats = defaults.listify
    case document
    when SolrDocument
      formats << "clio"

      document["format"].each do |format|
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

    # search value the same as the display value

    values.listify.collect do |v|
      case category
      when :all
        link_to(v, url_for(:controller => "catalog", :action => "index", :q => v, :search_field => "all_fields", :commit => "search"))
      when :author
        link_to(v, url_for(:controller => "catalog", :action => "index", :q => v, :search_field => "author", :commit => "search"))
      when :subject
        link_to(v, url_for(:controller => "catalog", :action => "index", :q => v, :search_field => "subject", :commit => "search"))
      when :title
        link_to(v, url_for(:controller => "catalog", :action => "index", :q => v, :search_field => "title", :commit => "search"))
      when :topic
        link_to(v, url_for(:controller => :catalog, :action => :index, "f[subject_topic_facet][]" => v))
      else
        raise "invalid category specified for generate_value_links"
      end
    end
  end

  def generate_value_links_2(values, category)

    # search value differs from display value
    # display value DELIM search value

    values.collect do |v|
      
      s = v.split(DELIM)
      
      case category
      when :all
        link_to(s[0], url_for(:controller => "catalog", :action => "index", :q => s[1], :search_field => "all_fields", :commit => "search"))
      when :author
        link_to(s[0], url_for(:controller => "catalog", :action => "index", :q => s[1], :search_field => "author", :commit => "search"))
      when :subject
        link_to(s[0], url_for(:controller => "catalog", :action => "index", :q => s[1], :search_field => "subject", :commit => "search"))
      when :title
        link_to(s[0], url_for(:controller => "catalog", :action => "index", :q => s[1], :search_field => "title", :commit => "search"))
      else
        raise "invalid category specified for generate_value_links"
      end
    end
  end

  def generate_value_links_subject(values, category)

    # search value the same as the display value
    # quote first term of the search string and remove ' - '

    values.listify.collect do |v|
      
      sub = v.split(" - ")
      out = '"' + sub.shift + '"'
      out += ' ' + sub.join(" ") unless sub.empty?
      
      link_to(v, url_for(:controller => "catalog", :action => "index", :q => out, :search_field => "subject", :commit => "search"))

    end
  end

  def add_row(title, value, options = {})
    options.reverse_merge!( {
      :display_blank => false,
      :display_only_first => false,
      :join => nil,
      :abbreviate => nil,
      :html_safe => true,
      :style => :definition
    })

    values = value.listify

    values = values.collect { |txt| txt.to_s.abbreviate(options[:abbreviate]) } if options[:abbreviate]
    value_txt = if options[:display_only_first] 
                  values.first.to_s 
                elsif options[:join]
                  values.join(options[:join]).to_s 
                else
                  values.collect { |v| content_tag(:div, v.to_s, :class => "entry") }.join("")
                end

    value_txt = value_txt.html_safe if options[:html_safe]  
    result = ""
    if options[:display_blank] || !value_txt.empty?

      result = content_tag(:div, :class => "row") do
        if options[:style] == :definition
          content_tag(:div, title.to_s, :class => "label") + content_tag(:div, content_tag(:div, value_txt, :class => "value_box"), :class => "value")
        elsif options[:style] == :blockquote
          content_tag(:div, content_tag(:div, value_txt, :class => "value_box"), :class => "blockquote")
        end

      end

    end

    result
  end
    
end
