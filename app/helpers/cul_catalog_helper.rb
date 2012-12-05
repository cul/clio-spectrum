# encoding: UTF-8
#
module CulCatalogHelper
  def expand_all_facets?
    session['options'] && session['options']['always_expand_facets'] == 'true'
  end

  def link_to_source_document(doc, opts={:label=>nil, :counter => nil, :results_view => true})
    label ||= blacklight_config.index.show_link.to_sym
    label = render_document_index_label doc, opts

    url = "/#{@active_source}/#{doc['id'].listify.first.to_s}"
    link_to label, url, :'data-counter' => opts[:counter]


  end
  def catalog_index_path(options = {})
    filtered_options = options.reject { |k,v| k.in?('controller', 'action','source_override') }
    source = options['source_override'] || @active_source

    "/#{source}?#{filtered_options.to_query}"

  end

  def active_source_path(options = {})
    url_params = options.reject { |k,v| k.in?('controller', 'action') }.to_query
    "/#{@active_source}?#{url_params}" 
  end

  def render_document_index_label doc, opts
    label = nil
    label ||= doc.get(opts[:label]) if opts[:label].instance_of? Symbol
    label ||= opts[:label].call(doc, opts) if opts[:label].instance_of? Proc
    label ||= opts[:label] if opts[:label].is_a? String
    label ||= doc.get("id")
    label.listify.join(" ").to_s 
  end


  SHORTER_LOCATIONS = {
    "Temporarily unavailable. Try Borrow Direct or ILL" => "Temporarily Unavailable",
    "Butler Stacks (Enter at the Butler Circulation Desk)" => "Butler Stacks",
    "Offsite - Place Request for delivery within 2 business days" => "Offsite",
    "Offsite (Non-Circ) Request for delivery in 2 business days" => "Offsite (Non-Circ)"
  }

  def shorten_location(location)
    SHORTER_LOCATIONS[location.strip] || location

  end

  def process_holdings_location(loc_display)
    loc,call = loc_display.split(' >> ')
    call ? "#{shorten_location(loc)} >> ".html_safe + content_tag(:span, call, class: 'call_number')  : shorten_location(loc)
  end


  def document_full_title(document)
    [document.get('title_display') , document.get('subtitle_display')].reject { |txt| txt.to_s.strip.empty? }.join(": ")
  end
  def build_fake_cover(document)
    book_label = (document["title_display"].to_s.abbreviate(60))
    content_tag(:div, content_tag(:div, book_label, :class => "fake_label"), :class => "cover fake_cover")

  end

  def build_holdings_hash(document)
    results = Hash.new { |h,k| h[k] = []}
    Holding.new(document["clio_id_display"]).fetch_from_opac!.results["holdings"].each_pair do |holding_id, holding_hash|
      results[[holding_hash["location_name"],holding_hash["call_number"]]] << holding_hash
    end

    if document["url_munged_display"] && !results.keys.any? { |k| k.first.strip == "Online" }
      results[["Online", "ONLINE"]] = [{"call_number" => "ONLINE", "status" => "noncirc", "location_name" => "Online"}]
    end
    results
  end

  URL_REGEX = Regexp.new('(?i)\b((?:[a-z][\w-]+:(?:/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:\'".,<>?«»“”‘’]))')
  

  def online_link_hash(document)
    
    links = []
    
    document["url_munged_display"].listify.each do |url_munge|
      url_parts = url_munge.split('~|Z|~').collect(&:strip)
      title = url =  ""
      if (url_index = url_parts.index { |part| part =~ URL_REGEX })
        url = url_parts.delete_at(url_index)
        title = url_parts.join(" ").to_s
        title = url if title.empty?
      else
        title = "Bad URL: " + url_parts.join(" ")
        url = ""
      end

      links << [title, url]
    end
    links
#    links.sort { |x,y| x.first <=> y.first }
  end

  def folder_link(document)
    size = "22x22"
    if item_in_folder?(document[:id])
      text = "Remove from folder"
      img = image_tag("icons/24-book-blue-remove.png", :size => size)
    else
      text = "Add to folder"
      img = image_tag("icons/24-book-blue-add.png", :size => size)
    end

    img + content_tag(:span, text, :class => "folder_link_text")
  end


end
