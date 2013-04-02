# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$ -> 
  if $('span.show_advanced_search').length == 0
    $('.advanced_search').hide()
  else
    $('.basic_search').hide()

  $('.advanced_search_toggle').click ->
    parent = $(this).parents('.search_boxes')
    parent.find('.advanced_search').toggle()
    parent.find('.basic_search').toggle()
