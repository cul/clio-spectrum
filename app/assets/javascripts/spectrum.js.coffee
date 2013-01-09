# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/



$ -> 
  $('.toggle_all.contract').parents("#facets").find('.range_limit').show()
  $('.toggle_all.contract').parents("#facets").find('ul').show()
  $('.toggle_all').click (e) ->
    e.preventDefault()
    expand = $(this).hasClass('expand')
    facets = $(this).parents('#facets')
    if expand
      facets.find('.limit_content').slideDown()
      facets.find('ul').slideDown()
      $(this).addClass('contract').removeClass('expand')
      $(this).text("Contract All")
      $('.expand_all_option').removeClass('hide').show()
    else
      facets.find('.limit_content').slideUp()
      facets.find('ul').slideUp()
      $(this).removeClass('contract').addClass('expand')
      $(this).text("Expand All")
      $('.expand_all_option').removeClass('hide').show()

  $('.toggle_expand_all_option').click ->
    if $(this).is(':checked')
      $.get('/set_user_option?name=always_expand_facets&value=true')
    else
      $.get('/set_user_option?name=always_expand_facets&value=false')

