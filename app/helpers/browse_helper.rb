# Call Number Browse
# 
# Based on Stanford SearchWorks
# 
module BrowseHelper


  def link_to_callnumber_browse(document, callnumber, index = 0)
    link_to(
      callnumber.callnumber,
      browse_index_path(
        start: document[:id],
        barcode: (callnumber.barcode unless callnumber.barcode == document[:preferred_barcode]),
        view: :gallery
      ), class: "collapsed",
         id: "callnumber-browse-#{index}",
         "aria-labelledby" => "callnumber-browse-#{index}",
         data: { behavior: "embed-browse",
                 start: document[:id],
                 embed_viewport: "#callnumber-#{index}",
                 url: browse_nearby_path(
                   start: document[:id],
                   barcode: (callnumber.barcode unless callnumber.barcode == document[:preferred_barcode]),
                   view: :gallery
                 )
               }
    )
  end

  def searchworks_link_to_callnumber_browse(document, callnumber, index = 0)
    link_to(
      callnumber.callnumber,
      browse_index_path(
        start: document[:id],
        barcode: (callnumber.barcode unless callnumber.barcode == document[:preferred_barcode]),
        view: :gallery
      ), class: "collapsed",
         id: "callnumber-browse-#{index}",
         "aria-labelledby" => "callnumber-browse-#{index}",
         data: { behavior: "embed-browse",
                 start: document[:id],
                 embed_viewport: "#callnumber-#{index}",
                 url: browse_nearby_path(
                   start: document[:id],
                   barcode: (callnumber.barcode unless callnumber.barcode == document[:preferred_barcode]),
                   view: :gallery
                 )
               }
    )
  end

  # Sometimes this throws routing errors:
  #   browse_shelfkey_full_path(session['browse']['shelfkey'])
  # Catch them instead of terminating.
  def build_browse_shelfkey_mini_path(shelfkey)
    path = nil
    return path unless shelfkey
    begin
      path = browse_shelfkey_mini_path(shelfkey)
    rescue ActionController::RoutingError
      return nil
    end
    return path
  end
  def build_browse_shelfkey_full_path(shelfkey)
    path = nil
    return path unless shelfkey
    begin
      path = browse_shelfkey_full_path(shelfkey)
    rescue ActionController::RoutingError
      return nil
    end
    return path
  end

end
