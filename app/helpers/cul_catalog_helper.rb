# encoding: UTF-8
#
module CulCatalogHelper
  def fix_catalog_links(text, source = @active_source)
    text.to_s.gsub('/catalog',"/#{source}").html_safe
  end

  def build_link_back()
    # 1) EITHER start basic - just go back to where we came from... even if 
    # it was a link found on a web page or in search-engine results...
    # link_back = request.referer.path
    # 2) OR have no "back" support unless the below works:
    link_back = nil
    begin
      # try the Blacklight approach of reconstituting session[:search] into
      # a search-results-list URL...
      link_back = link_back_to_catalog
      # ...but this can easily fail in multi-page web interactions, so catch errors
    rescue ActionController::RoutingError
    end

    # send back whatever we ended up with.
    return link_back
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



  def document_full_title(document)
    [document.get('title_display') , document.get('subtitle_display')].reject { |txt| txt.to_s.strip.empty? }.join(": ")
  end
  def build_fake_cover(document)
    book_label = (document["title_display"].to_s.abbreviate(60))
    content_tag(:div, content_tag(:div, book_label, :class => "fake_label"), :class => "cover fake_cover")

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
