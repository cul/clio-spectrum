$ ->

  $('.turn_async_off').hide()

  $('.result_set.async_result_set').each ->
    result_set = $(this)
    url = result_set.attr('data-result-set')
    $.get(url, (data) ->
      result_set.html(data)
    )
  
