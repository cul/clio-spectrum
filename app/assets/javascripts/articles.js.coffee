$ -> 
  $('.search_option_action').click ->
    # NEXT-836 - Can't uncheck multiple options at the same time
    $('.busy').show()
    window.location.href = $(this).attr('href')

