$ -> 
  $('.search_option_action').click ->
    window.location.href = $(this).attr('href')

  if $('span.show_advanced_search').length == 0
    $('.advanced_search_well').hide()

  $('.advanced_search_toggle').click ->
    toggle_link = this
    $('.advanced_search_well').toggle()
    if $('.advanced_search_well').is(':visible')
      $(this).html('Less Options')
    else
      $(this).html('More Options')
