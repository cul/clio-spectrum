
$ ->

  # Toggle the mini-shelf-browse list - On / Off

  # OFF
  $('.hide_mini_browse').click ->
    $('#mini_browse_list').hide()
    $('.hide_mini_browse').toggleClass('disabled')
    $('.show_mini_browse').toggleClass('disabled')
    $('.call_number_toggle').toggleClass('disabled')
    $('.call_number_nav').toggleClass('disabled')

  # ON
  $('.show_mini_browse').click ->
    # Load (or re-load) the "nearby" list for the active shelfkey
    active_shelfkey = $('.call_number_toggle.active').data('shelfkey')
    active_bib = $('.call_number_toggle.active').data('bib')
    load_shelfkey(active_shelfkey, active_bib)
    $('#mini_browse_list').show()
    $('.hide_mini_browse').toggleClass('disabled')
    $('.show_mini_browse').toggleClass('disabled')
    $('.call_number_toggle').toggleClass('disabled')
    $('.call_number_nav').toggleClass('disabled')


  # Toggle between multiple call-numbers
  $('.call_number_toggle').click ->
    # nope, the 'active' class isn't present yet
    # active_shelfkey = $('.call_number_toggle.active').data('shelfkey')
    clicked_shelfkey = $(this).data("shelfkey")
    clicked_bib = $(this).data("bib")
    load_shelfkey(clicked_shelfkey, clicked_bib)


  # Full Screen
  # Needs to be javascript, to detect the currently active toggle button
  $('.call_number_full_screen').click ->
      full_path = $(this).data("full-path")
      active_shelfkey = $('.call_number_toggle.active').data('shelfkey')
      active_bib = $('.call_number_toggle.active').data('bib')
      full_path_to_shelfkey = full_path.replace('SHELFKEY', active_shelfkey)
      if (typeof active_bib != 'undefined')
        full_path_to_shelfkey = full_path_to_shelfkey + "/" + active_bib
      window.location = full_path_to_shelfkey 
      return false


# function to replace the html content of our #nearby object 
# with the shelf-key view of  looked-up nearby items


@load_shelfkey = (shelfkey, bib) ->
  # active_shelfkey = $('.call_number_toggle.active').data('shelfkey')
  $("#nearby .nearby_spinner").show()
  $("#nearby .nearby_error").hide()
  $("#nearby .nearby_content").hide()
  mini_browse_url = '/browse/shelfkey_mini/' + shelfkey
  if (typeof bib != 'undefined')
    mini_browse_url = mini_browse_url + "/" + bib

  $.ajax
    url: mini_browse_url
  
    success: (data) ->
        $('#nearby .nearby_content').html(data)
        $("#nearby .nearby_spinner").hide()
        $("#nearby .nearby_error").hide()
        $("#nearby .nearby_content").show()
        async_lookup_item_details($('#outer-container'))
  
    error: (data) ->
        $("#nearby .nearby_spinner").hide()
        $("#nearby .nearby_error").show()
        $("#nearby .nearby_content").hide()


