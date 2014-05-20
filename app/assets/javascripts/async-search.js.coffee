$ ->

  $('.result_set.async_result_set').each ->
    result_set = $(this)
    url = result_set.attr('data-result-set')
    $.get(url, (data) ->
      result_set.html(data)
      # re-activate popovers on the re-written html:
      $("a[rel='popover']").popover()
      async_lookup_item_details(result_set)
    )

