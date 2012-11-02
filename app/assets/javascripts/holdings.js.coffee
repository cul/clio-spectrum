$(document).ready ->
    
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
 
  

  $(".datasource_link,.datasource_drop_link").click ->
    change_datasource($(this).attr('source'))
    #$("#mobile_datasource_select").val($(this).attr('source'))


  $("#top_search_box .q").observe_field(.25, -> 
      if $(this).is(":visible")
        value = $(this).val()
        $("#top_search_box .q:hidden").val(value)
    
  )

  $(".return-to-index").attr('style', "display: none")

  $("#select_a_help_issue a").click (e) ->
    e.preventDefault();
    $(this).tab('show');
    $(".return-to-index").show()
    $("#select_a_help_issue").hide()

  $(".return-to-index btn.submit").click ->
    $(this).html = "Sending..."
    form = $(this).parents('form')
    $.post '/backend/feedback_mail', form.serialize(), () -> 
      $('#helptab_content .tab-pane.active').hide()
      $('#success_message').show().delay(1000)
      $('#helpModal').modal(show: 'false')

  $(".return-to-index btn.return").click ->
    $(".return-to-index").hide()
    $("#helptab_content .tab-pane.active").removeClass('active')
    $("#select_a_help_issue").show()

  $(".expander").click ->
    $(this).hide()
    $(this).parent().find(".expander_more").show()
    return false

  bind_dropdown_selects()

  $("#mobile_datasource_select").change ->
    select = '#datasources li[source="' + $(this).val() + '"] a'
    datasource_href= $(select).attr('href')

    if datasource_href == '#'
      change_datasource($(this).val())
    else
      window.location = datasource_href

bind_dropdown_selects = (source) ->
  $(".dropdown_select_tag").each ->
    $(this).find('ul.dropdown-menu a').click ->
      selection = $(this).attr('data-value')
      selection_key = $(this).text()

      dropdown_root = $(this).parents(".dropdown_select_tag")
      $(dropdown_root).find('.dropdown-toggle').html(selection_key + ' <span class="caret"/>')
      console.log($(dropdown_root).find('select').val())
      $(dropdown_root).find('select').val(selection)
      console.log($(dropdown_root).find('select').val())


change_datasource = (source) ->
  $("ul.landing li").removeClass('selected')
  $("ul.landing li[source='" + source + "']").addClass('selected')

  landing_selector = ".landing_page." + source
  $('.landing_page').hide()
  $(landing_selector).show()
  
  search_box_select = "#top_search_box .search_box." + source
  $('#top_search_box .search_box.multi').hide()
  $(search_box_select).show()



root = exports ? this
root.load_clio_holdings = (id) -> 
  $("span.holding_spinner").show
  $("#clio_holdings .holdings_error").hide

  $.ajax
    url: '/backend/holdings/' + id

    success: (data) ->
        $('#clio_holdings').html(data)

    error: (data) ->
        $("span.holding_spinner").hide()
        $('#clio_holdings .holdings_error').show()

root.retrieve_fedora_resources = (fedora_ids) ->
  url = 'http://rossini.cul.columbia.edu/voyager_backend/fedora/resources/' + fedora_ids.join('/');

  $.getJSON url, (data) ->
    for fedora_id, resources of data
      fedora_selector = '.fedora_' + fedora_id.replace(':','')
      $(fedora_selector).html('')
      first_resource = true

      for i, resource of resources
        first_resource = false
        if resource['content_type'][0] && resource['content_type'][0] = "application/pdf"
          resource_type = 'pdf'
        else
          resource_type = 'default'


        txt = '<div class="entry"><img src="/assets/fedora_icons/' + resource_type + '.png" width="16" height="16"/> <a href="' + resource['download_path'] + '">' + resource['filename'] + '</a></div>'
        $(fedora_selector).append(txt)

      if first_resource
        $(fedora_selector).html('No downloads found for this item.')


root.retrieve_holdings = (bibids) ->
  url = 'http://rossini.cul.columbia.edu/voyager_backend/holdings/retrieve/' + bibids.join('/');
  

  $.getJSON url, (data) -> 
    for bib, holdings of data
      for i, holding of data[bib].condensed_holdings_full
        for j, holding_id of holding.holding_id
          selector = "img.availability.holding_" + holding_id
          $(selector).attr("src", "/assets/icons/"+holding.status+".png")

