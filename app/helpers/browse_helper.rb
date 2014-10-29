# Call Number Browse
# 
# Based on Stanford SearchWorks
# 
module BrowseHelper

  # ABORT - this is getting ridiculous, move it to a partial...
  # # Display toggle-buttons of each Call-Number associated with this document
  # # Using  http://getbootstrap.com/javascript/#buttons
  # def call_number_toggles(document)
  #   content_tag(:div, class:'btn-group') do
  #     document['item_display'].map { |item_display|
  #       concat(content_tag(:div, get_call_number(item_display), type: 'button', id: get_shelfkey(item_display), class: 'btn btn-default'))
  #     }
  #   end
  # 
  #   # return content_tag(:div, buttons, class:'btn-group')
  # end


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
