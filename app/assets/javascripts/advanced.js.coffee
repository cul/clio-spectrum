

$ ->
  # magic span indicator is written into the HTML if an ADV search is in effect,
  # onload set visibility of Basic v.s. Advanced
  # (although this might be set correctly during page rendering)
  #if $('span.show_advanced_search').length == 0
    #$('.basic_search').show()
    #$('.advanced_search').hide()
  #else
    #$('.basic_search').hide()
    #$('.advanced_search').show()

  # Set hide/show state of any .search_box on page load
  # (although this should be done already on render)
  $('.search_box.selected').show()
  $('.search_box').not('.selected').hide()

  # And, listen to the toggle link to flip visibility
  $('.advanced_search_toggle').click ->
    parent = $(this).parents('.search_boxes')
    parent.find('.advanced_search .search_box').toggle()
    parent.find('.basic_search .search_box').toggle()
 

