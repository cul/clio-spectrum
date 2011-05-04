module CatalogHelper

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

  def online_link_title(document, index)
    title = ""

    if (detail = document["url_detail"].listify[index]) || (note = document["url_detail_note"].listify[index])
      title = [detail, note].compact.join(" ")
    else
      title = document["url_fulltext_display"].listify[index].to_s.abbreviate(50)
    end

    return auto_add_empty_spaces(h(title))
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
  def page_entries_info(collection, options = {})
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
