
$ ->

  # Toggle the mini-shelf-browse list - On / Off

  $('.hide_mini_browse').click ->
    $('#mini_browse_list').hide()
    $('.hide_mini_browse').toggleClass('disabled')
    $('.show_mini_browse').toggleClass('disabled')
    $('.call_number_toggle').toggleClass('disabled')
    $('.call_number_nav').toggleClass('disabled')

  $('.show_mini_browse').click ->
    $('#mini_browse_list').show()
    $('.hide_mini_browse').toggleClass('disabled')
    $('.show_mini_browse').toggleClass('disabled')
    $('.call_number_toggle').toggleClass('disabled')
    $('.call_number_nav').toggleClass('disabled')

  # Toggle between multiple call-numbers
  $('.call_number_toggle').click ->
    shelfkey = $(this).data("shelfkey")
    load_nearby( shelfkey )


# function to replace the html content of our #nearby object 
# with the shelf-key view of  looked-up nearby items

@load_nearby = (shelfkey) ->
  $('#nearby').html("")
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