$ ->
  $("ul#datasources li, #toolbar-container .box").hover(
    -> $(this).addClass('hover')
    -> $(this).removeClass('hover')
  )


  # Toggle datasources list between partial and full

  $("#datasource_expand").click ->
    $(this).hide()
    $("#expanded_datasources").slideDown()

  $("#datasource_contract").click ->
    $("#expanded_datasources").slideUp(
      100
      -> $("#datasource_expand").show()
    )


  $("#mobile_datasource_select").change ->
    select = '#datasources li[source="' + $(this).val() + '"] a'
    datasource_href= $(select).attr('href')

    # if datasource_href == '#'
    #   change_datasource($(this).val())
    # else
    if datasource_href != '#'
      $('.busy').show()
      window.location = datasource_href


  $('.datasource-hits.fetch').each ->
    # datasource = $(this).data('datasource')
    # query = $(this).data('query')
    # url = '/spectrum/hits/' + datasource+ '?q=' + query

    hit_span = $(this)
    hits_url = $(this).data('hits-url')

    # alert(hits_url)
    if typeof hits_url != 'undefined'
      $.get(hits_url, (data) ->
        hit_span.html(data)
      )
    


