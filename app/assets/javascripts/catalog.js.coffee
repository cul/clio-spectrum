$ ->

  $(".expander").click ->
    $(this).hide()
    $(this).parent().find(".expander_more").show()
    return false

  $(".viewstyle_link").click ->
    viewstyle = $(this).attr('viewstyle')    
    $.get '/set_user_option?name=viewstyle&value=' + viewstyle, (data) ->
      location.reload()


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


