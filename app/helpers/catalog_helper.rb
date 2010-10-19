module CatalogHelper

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

    display_items += link_to(image_tag("rss-feed-icon-14x14.png"), catalog_index_path(params.merge(:format => "rss")), :id => "feedLink")
  end


end
