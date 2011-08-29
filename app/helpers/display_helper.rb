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
    "Music - Recording" => "music",
    "Music - Score" => "music"
  }

  FORMAT_RANKINGS = ["music", "clio", "ebooks", "article", "lweb"]

  def determine_formats(document, defaults = [])
    formats = defaults.listify
    if document.kind_of?(SolrDocument)
      formats << "clio"

      document["format"].each do |format|
        formats << SOLR_FORMAT_LIST[format] if SOLR_FORMAT_LIST[format]
      end
    end

    formats.sort { |x,y| FORMAT_RANKINGS.index(x) <=> FORMAT_RANKINGS.index(y) }
  end


  def generate_value_links(values, category)

    values.listify.collect do |v|
      case category
      when :author

        link_to(v, url_for(:controller => "catalog", :action => "index", :q => v, :search_field => "author", :commit => "search"))
      when :topic
        link_to(v, url_for(:controller => :catalog, :action => :index, "f[subject_topic_facet][]" => v))


      else
        raise "invalid category specified for generate_value_links"
      end
    end
  end

  def get_marc_values(marc, field, subfields = :all)
    marc[field].listify.collect do |v| 
      v.subfields.select { |sf| subfields == :all || subfields.include?(sf.code) }.collect(&:value)
    end.flatten
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
