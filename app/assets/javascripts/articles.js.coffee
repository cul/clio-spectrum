$ -> 
  $('.search_option_action').click ->
    window.location.href = $(this).attr('href')

  $('.advanced_search_well').hide()

  $('.advanced_search_toggle').click ->
    $('.advanced_search_well').toggle()
