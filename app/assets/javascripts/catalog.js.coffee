$ ->

  $(".expander").click ->
    $(this).hide()
    $(this).parent().find(".expander_more").show()
    return false

  $(".viewstyle_link").click ->
    $('.busy').show()
    viewstyle = $(this).attr('viewstyle')    
    request = $.get '/set_browser_option?name=viewstyle&value=' + viewstyle, cache: false
    request.done (data, textStatus, jqXHR) -> 
      # console.log "done. textStatus: " + textStatus
      # pass "true" to force reload from server, instead of from cache
      location.reload(true)
    request.fail (jqXHR, textStatus, errorThrown) -> 
      # console.log "fail. textStatus: " + textStatus + " / errorThrown: " + errorThrown
      $('.busy').hide()
    request.always (data_or_jqXHR, textStatus, jqXHR_or_errorThrown) -> 
      # console.log "always.  textStatus: " + textStatus


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
      $.get('/set_browser_option?name=always_expand_facets&value=true')
    else
      $.get('/set_browser_option?name=always_expand_facets&value=false')


