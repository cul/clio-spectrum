$('.dropdown-toggle').dropdown()
$(document).ready ->
  $('.dropdown_select_tag').each (index,container) ->
    $(container).children('select').hide()
    $(container).children('.dropdown-toggle').show()
