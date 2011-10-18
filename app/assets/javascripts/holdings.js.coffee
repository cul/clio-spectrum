$(document).ready ->
  attach_location_colorboxes()
  $(".dropmenu").dropmenu()


attach_location_colorboxes = ->
  $(".location_display").colorbox
    transition: 'none'
    scrolling: false


root = exports ? this
root.load_clio_holdings = (id) -> 

  $("span.holding_spinner").show
  $("#clio_holdings .holdings_error").hide

  $.ajax
    url: '/backend/holdings/' + id

    success: (data) ->
        $('#clio_holdings').html(data)
        attach_location_colorboxes()

    error: (data) ->
        $("span.holding_spinner").hide()
        $('#clio_holdings .holdings_error').show()
