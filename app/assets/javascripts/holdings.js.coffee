$(document).ready ->
  attach_location_colorboxes()
  $(".dropmenu").dropmenu()
  $("ul#datasources li, #toolbar-container .box").hover(
    -> $(this).addClass('hover')
    -> $(this).removeClass('hover')
  )

  $("#datasource_expand").click -> 
    $(this).hide()
    $("#expanded_datasources").slideDown()

  $("#datasource_contract").click ->
    $("#expanded_datasources").slideUp(
      100
      -> $("#datasource_expand").show()
    )
  

  $(".datasource_link").click ->
    change_datasource($(this).attr('source'))


change_datasource = (source) ->
  $("ul.landing li").removeClass('selected')
  $("ul.landing li[source='" + source + "']").addClass('selected')

  landing_selector = ".landing_page." + source
  $('.landing_page').hide()
  $(landing_selector).show()
  
  search_box_select = "#top_search_box .search_box." + source
  $('#top_search_box .search_box').hide()
  $(search_box_select).show()

attach_location_colorboxes = ->
  $(".location_display").colorbox
    transition: 'none'
    scrolling: false


root = exports ? this
root.load_clio_holdings = (id) -> 
  $("span.holding_spinner").show
  $("#clio_holdings .holdings_error").hide

  $.ajax
    url: '/backend/holdings/' + id

    success: (data) ->
        $('#clio_holdings').html(data)
        attach_location_colorboxes()

    error: (data) ->
        $("span.holding_spinner").hide()
        $('#clio_holdings .holdings_error').show()

root.retrieve_holdings = (bibids) ->
  url = 'http://rossini.cul.columbia.edu/voyager_backend/holdings/retrieve/' + bibids.join('/');
  

  $.getJSON url, (data) -> 
    for bib, holdings of data
      for i, holding of data[bib].condensed_holdings_full
        for j, holding_id of holding.holding_id
          selector = "img.availability.holding_" + holding_id
          $(selector).attr("src", "/assets/icons/"+holding.status+".png")


