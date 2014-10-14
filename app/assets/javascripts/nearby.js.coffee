@load_nearby = (shelfkey) ->
  $("span.nearby_spinner").show
  $("#nearby .nearby_error").hide

  $.ajax
    url: '/browse/shelfkey_mini/' + shelfkey
  
    success: (data) ->
        $('#nearby').html(data)
        async_lookup_item_details($('#outer-container'))
  
    error: (data) ->
        $("span.nearby_spinner").hide()
        $('#nearby .nearby_error').show()
