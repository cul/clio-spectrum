
$ ->

  # Toggle the mini-shelf-browse list - On / Off

  # OFF
  $('.hide_mini_browse').click ->
    $('#mini_browse_list').hide()
    $('.hide_mini_browse').toggleClass('disabled')
    $('.show_mini_browse').toggleClass('disabled')
    # $('.call_number_toggle').toggleClass('disabled')

  # ON
  $('.show_mini_browse').click ->
    # First, make sure that some call-number is active.
    # If nothing is currently active, make the first one active.
    if ( $('.call_number_toggle.active').length == 0)
      $('.call_number_toggle').first().toggleClass('active')
    # Load (or re-load) the "nearby" list for the active shelfkey
    active_shelfkey = $('.call_number_toggle.active').data('shelfkey')
    active_bib = $('.call_number_toggle.active').data('bib')
    load_shelfkey(active_shelfkey, active_bib)
    $('.hide_mini_browse').toggleClass('disabled')
    $('.show_mini_browse').toggleClass('disabled')
    # $('.call_number_toggle').toggleClass('disabled')


  # Toggle between multiple call-numbers
  $('.call_number_toggle').click ->
    # We always allow clicking on call-numbers, and this click
    # should assert Hide/Show button state to "Show"
    $('.hide_mini_browse').removeClass('disabled')
    $('.show_mini_browse').addClass('disabled')
    
    # Can't do this - 'active' class isn't added until post-click-handler
    # active_shelfkey = $('.call_number_toggle.active').data('shelfkey')
    # Do this instead:
    clicked_shelfkey = $(this).data("shelfkey")
    clicked_bib = $(this).data("bib")
    load_shelfkey(clicked_shelfkey, clicked_bib)


  # refactor to do this in haml, not javascript, which gives better
  # browser support for bookmarks, copy-link, open-in-new-window, etc, etc.
  # # Full Screen
  # # Needs to be javascript, to detect the currently active toggle button
  # $('.call_number_full_screen').click ->
  #     full_path = $(this).data("full-path")
  #     active_shelfkey = $('.call_number_toggle.active').data('shelfkey')
  #     active_bib = $('.call_number_toggle.active').data('bib')
  #     full_path_to_shelfkey = full_path.replace('SHELFKEY', active_shelfkey)
  #     if (typeof active_bib != 'undefined')
  #       full_path_to_shelfkey = full_path_to_shelfkey + "/" + active_bib
  #     window.location = full_path_to_shelfkey 
  #     return false

  # Again, we're switching to haml for this, to re-use nav logic between
  # mini and full screens for consistent look & feel
  # # These need to support before and after counts, just like full-page...
  # $('.call_number_nav_previous').click ->
  #   firstShelfkey = $('.nearby_content #documents').data('firstShelfkey')
  #   # alert("firstShelfkey="+firstShelfkey)
  #   load_shelfkey(firstShelfkey, 0, 9)
  # 
  # $('.call_number_nav_next').click ->
  #   lastShelfkey = $('.nearby_content #documents').data('lastShelfkey')
  #   # alert("lastShelfkey="+lastShelfkey)
  #   load_shelfkey(lastShelfkey, 0, 0)
  


# Install click-handlers to AJAX-loaded html content
# (can't be done at initial page load)
@install_toolbar_click_handlers = () ->

  $('#mini_browse_list .call_number_nav_previous').click ->
    firstShelfkey = $(this).data('firstshelfkey')
    load_shelfkey(firstShelfkey, 0, 9)
    return false

  $('#mini_browse_list .call_number_nav_next').click ->
    lastShelfkey = $(this).data('lastshelfkey')
    load_shelfkey(lastShelfkey, 0, 0)
    return false

  $('#mini_browse_list .call_number_jump').click ->
    jump_shelfkey = $(this).data('shelfkey')
    # alert('Clicked JUMP to ' + jump_shelfkey + ' within mini-browse!')
    load_shelfkey(jump_shelfkey, 0)
    return false
    
    

# function to replace the html content of our #nearby object 
# with the shelf-key view of  looked-up nearby items

@load_shelfkey = (shelfkey, bib, before_count) ->
  $('#mini_browse_list').show()
  $("#nearby .nearby_spinner").show()
  $("#nearby .nearby_error").hide()
  $("#nearby .nearby_content").hide()
  mini_browse_url = '/browse/shelfkey_mini/' + shelfkey
  if (typeof bib != 'undefined'  &&  bib > 0)
    mini_browse_url = mini_browse_url + "/" + bib
  if (typeof before_count == 'undefined')
    before_count = 2
  mini_browse_url = mini_browse_url + '?before=' + before_count

  $.ajax
    url: mini_browse_url
  
    success: (data) ->
        $('#nearby .nearby_content').html(data)
        install_toolbar_click_handlers()
        $("#nearby .nearby_spinner").hide()
        $("#nearby .nearby_error").hide()
        $("#nearby .nearby_content").show()
        async_lookup_item_details($('#outer-container'))
        false
  
    error: (data) ->
        $("#nearby .nearby_spinner").hide()
        $("#nearby .nearby_error").show()
        $("#nearby .nearby_content").hide()


