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

# 
#  DISABLE - this never worked well with the browser's
#            back/forward buttons, so go back to normal
#            page fetches for landing pages.
# (see NEXT-978 - "Back" button broken in CLIO)
# 
  # # Fire-off Javascript-based switching between datasources
  # $(".datasource_link").click ->
  #   change_datasource($(this).attr('source'))
  #   #$("#mobile_datasource_select").val($(this).attr('source'))


# This code copies the value entered in the visible basic-search-box
# to all the hidden basic-search-boxes.
# This is only relevant for Javascript-based datasource-switching.
# When we use real href links to point to other datasources, we
# build those links to include "q", if defined.
# Note - text entered but not yet searched-upon used to transfer
# between datasources.  This no longer works.  Does this matter?
  # $(".basic_search .search_q").observe_field(.25, ->
  #     if $(this).is(":visible")
  #       value = $(this).val()
  #       $(".basic_search .search_q:hidden").val(value)
  # )

  # bind_dropdown_selects()


  $("#mobile_datasource_select").change ->
    select = '#datasources li[source="' + $(this).val() + '"] a'
    datasource_href= $(select).attr('href')

    # if datasource_href == '#'
    #   change_datasource($(this).val())
    # else
    if datasource_href != '#'
      $('.busy').show()
      window.location = datasource_href

# remove Bootstrap-Dropdown-Menu-as-Select-Tag
# bind_dropdown_selects = (source) ->
#   $(".dropdown_select_tag").each ->
#     $(this).find('ul.dropdown-menu a').click ->
#       selection = $(this).attr('data-value')
#       selection_key = $(this).text()
# 
#       dropdown_root = $(this).parents(".dropdown_select_tag")
#       $(dropdown_root).find('.dropdown-toggle').html(selection_key + ' <span class="caret"/>')
#       $(dropdown_root).find('select').val(selection)

# # Capture the browser's forward/backward events, 
# # send them to change_datasource()
# window.onpopstate = (event) ->
#   if event.state && event.state.source
#     change_datasource(event.state.source)
# 
# 
# 
# # Javascript-based switching between datasources,
# # with attempted manipulation of the browser history
# change_datasource = (source) ->
#   $("ul.landing li").removeClass('selected')
#   $("ul.landing li[source='" + source + "']").addClass('selected')
#   history.pushState?({source: source}, '', source + "#")
# 
#   landing_selector = ".landing_page." + source
#   $('.landing_page').hide()
#   $(landing_selector).show()
# 
#   search_box_select = ".basic_search .search_box." + source
#   $('.basic_search .search_box.multi').hide()
#   $(search_box_select).show()
# 


