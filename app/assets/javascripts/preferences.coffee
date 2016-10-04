# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $('#bento_left, #bento_right, #bento_inactive').sortable
    connectWith: '.bento_list'
    
  $('#serialize').click ->
    left_sources = $('#bento_left').sortable("toArray")
    left_counts = []
    for source in left_sources
      id = "#" + source + "_count"
      param = source + ":" + $(id).val()
      left_counts.push(param)
    right_counts = []

    right_sources = $('#bento_right').sortable("toArray")
    for source in right_sources
      id = "#" + source + "_count"
      param = source + ":" + $(id).val()
      right_counts.push(param)

    $.post $(this).data("bento-url"), {bento_left: left_counts, bento_right: right_counts}