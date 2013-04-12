root = exports ? this

root.after_document_load = (element) ->
  fedora_items = []
  catalog_items = []
  google_items = []
  $(element).find('.result').each ->
    res = $(this)
    source = res.attr('source')
    item = res.attr('item_id')

    if source == 'academic_commons'
      fedora_items.push(item)
    else if source == 'catalog'
      catalog_items.push(item)
      google_items.push.apply(google_items, res.attr('google_ids').split(","))

  if fedora_items.length
    retrieve_fedora_resources(fedora_items)
   
  if catalog_items.length
    retrieve_holdings(catalog_items)

  #console.log?(catalog_items)
  #console.log?(google_items)


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
  url = 'http://rossini.cul.columbia.edu/voyager_backend/holdings/status/' + bibids.join('/');
  

  $.getJSON url, (data) -> 
    for bib, holdings of data
      for holding_id, status of data[bib].statuses
        selector = "img.availability.holding_" + holding_id
        $(selector).attr("src", "/assets/icons/"+ status+".png")




root.update_book_jackets = (isbns, data) ->
  for index of isbns
    isbn = isbns[index]
    isbn_name = isbn.replace(/:/, "")
    selector = $("img.bookjacket[src*='assets/spacer'].isbn_" + isbn_name)
    isbn_data = data[isbn]

    if selector.length > 0 and isbn_data
      selector.parents("#show_cover").show()
      gbs_cover = selector.parents(".gbs_cover")
    
      if isbn_data.thumbnail_url
        selector.attr "src", isbn_data.thumbnail_url.replace(/zoom\=5/, "zoom=1")
        selector.parents(".book_cover").find(".fake_cover").hide()
        gbs_cover.show()
      
      $("li.gbs_info").show()
      $("a.gbs_info_link").attr "href", isbn_data.info_url
      
      unless isbn_data.preview is "noview"
        gbs_cover.find(".gbs_preview").show()
        gbs_cover.find(".gbs_preview_link").attr "href", isbn_data.preview_url
      
        search_form = gbs_cover.find(".gbs_search_form")
        search_form.show()
        
        find_id = new RegExp("[&?]id=([^&(.+)=]*)").exec(isbn_data.preview_url)
        strip_querystring = new RegExp("^[^?]+").exec(isbn_data.preview_url)
        
        if find_id and strip_querystring
          search_form.attr("action", strip_querystring[0]).show()
          search_form.find("input[name=id]").attr "value", find_id[1]
        
        gbs_cover.find(".gbs_preview_partial").show()  if isbn_data.preview is "partial"
        gbs_cover.find(".gbs_preview_full").show()  if isbn_data.preview is "full"

$ -> 
  after_document_load($('#page'))

