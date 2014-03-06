
# "Call the dropdowns via JavaScript" - what does this mean?
# http://getbootstrap.com/2.3.2/javascript.html#dropdowns
$('.dropdown-toggle').dropdown()

$(document).ready ->
  $('.dropdown_select_tag').each (index, container) ->
    $(container).children('select').hide()
    $(container).children('.dropdown-toggle').show()
