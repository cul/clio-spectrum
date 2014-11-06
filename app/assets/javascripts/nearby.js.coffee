
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
    # active_shelfkey = $('.call_number_toggle.active').data('shelfkey')
    # load_nearby( active_shelfkey )
    load_active_shelfkey()
    $('#mini_browse_list').show()
    $('.hide_mini_browse').toggleClass('disabled')
    $('.show_mini_browse').toggleClass('disabled')
    $('.call_number_toggle').toggleClass('disabled')
    $('.call_number_nav').toggleClass('disabled')

  # Toggle between multiple call-numbers
  $('.call_number_toggle').click ->
    # shelfkey = $(this).data("shelfkey")
    # load_nearby( shelfkey )
    load_active_shelfkey()


# function to replace the html content of our #nearby object 
# with the shelf-key view of  looked-up nearby items

@load_active_shelfkey = () ->
  active_shelfkey = $('.call_number_toggle.active').data('shelfkey')
  $("#nearby .nearby_spinner").show()
  $("#nearby .nearby_error").hide()
  $("#nearby .nearby_content").hide()

  $.ajax
    url: '/browse/shelfkey_mini/' + active_shelfkey
  
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


          # 
          # 
          # .row
          #   .col-xs-4
          #     %h4=Shelf Browse
          #     .btn-group
          #       .btn.btn-default.hide_mini_browse{type: 'button'}Off
          #       .btn.btn-default.show_mini_browse{type: 'button'}On
          #   .col-xs-4
          #     = link_to "Full Screen", browse_shelfkey_full_path( first_shelfkey)
          #   .col-xs-4
          #     
          #     -# = call_number_toggles(document)
          # #mini_browse_list.row.hidden
          #   .col-xs-12
          #     = render "/_f