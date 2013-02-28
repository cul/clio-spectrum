$ -> 
  $('.search_option_action').click ->
    window.location.href = $(this).attr('href')

  if $('span.show_advanced_search').length == 0
    $('.advanced_search').hide()
  else
    $('.basic_search').hide()

  $('.advanced_search_toggle').click ->
    parent = $(this).parents('.search_boxes')
    parent.find('.advanced_search').toggle()
    parent.find('.basic_search').toggle()
