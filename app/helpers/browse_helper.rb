# Call Number Browse
# 
# Based on Stanford SearchWorks
# 
module BrowseHelper

  # Display toggle-buttons of each Call-Number associated with this document
  # Using  http://getbootstrap.com/javascript/#buttons
  def call_number_toggles(document)
    buttons = document['item_display'].each_with_index { |item_display, counter|
      content_tag(:label, content_tag(:input, get_call_number(item_display), type: 'radio', name: 'call_number', id: get_shelfkey(item_display)), class: 'btn btn-primary')
    }.join("\n")

    return content_tag(:div, buttons, class:'btn-group', 'data-toggle' => 'buttons')
  end


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


end
