# encoding: UTF-8
#
module CulCatalogHelper
  def render_document_index_label doc, opts
    label = nil
    label ||= doc.get(opts[:label]) if opts[:label].instance_of? Symbol
    label ||= opts[:label].call(doc, opts) if opts[:label].instance_of? Proc
    label ||= opts[:label] if opts[:label].is_a? String
    label ||= doc.id
    label.listify.join(" ").to_s 
  end


  SHORTER_LOCATIONS = {
    "Temporarily unavailable. Try Borrow Direct or ILL" => "Temporarily Unavailable",
    "Butler Stacks (Enter at the Butler Circulation Desk)" => "Butler Stacks"
  }

  def shorten_location(location)
    SHORTER_LOCATIONS[location.strip] || location

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

    links.sort { |x,y| x.first <=> y.first }
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

      
  #
  # Displays the "showing X through Y of N" message. Not sure
  # why that's called "page_entries_info". Not entirely sure
  # what collection argument is supposed to duck-type too, but
  # an RSolr::Ext::Response works.  Perhaps it duck-types to something
  # from will_paginate?
  def page_entries_info_with_rss(collection, options = {})
    start = collection.next_page == 2 ? 1 : collection.previous_page * collection.per_page + 1
    total_hits = @response.total
    start_num = format_num(start)
    end_num = format_num(start + collection.per_page - 1)
    total_num = format_num(total_hits)

    entry_name = options[:entry_name] ||
      (collection.empty?? 'entry' : collection.first.class.name.underscore.sub('_', ' '))

    display_items = if collection.total_pages < 2
      case collection.size
      when 0; "No #{entry_name.pluralize} found"
      when 1; "Displaying <b>1</b> #{entry_name}"
      else;   "Displaying <b>all #{total_num}</b> #{entry_name.pluralize}"
      end
    else
      "Displaying #{entry_name.pluralize} <b>#{start_num} - #{end_num}</b> of <b>#{total_num}</b>"
    end

    display_items += link_to(image_tag("rss-feed-icon-14x14.png"), catalog_index_path(params.merge(:format => "atom")), :id => "feedLink")
  end

end
