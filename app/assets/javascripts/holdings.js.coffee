
$ ->
  # async_lookup_item_details($('#page'))
  async_lookup_item_details($('#outer-container'))


# async_lookup_item_details called here, on document-ready,
# and also from async-search.js.coffee, once per panel in aggregates

@async_lookup_item_details = (element) ->
  fedora_items = []
  catalog_items = []
  standard_id_sets = []
  $(element).find('.result').each ->
    res = $(this)
    source = res.attr('source')
    item = res.attr('item_id')

    # alert("item:" + item)

    if source == 'academic_commons'
      fedora_items.push(item)
    else if source == 'catalog'
      # alert("numeric item:" + item)
      # exclude Law records from the catalog holdings check
      # (but leave them in standard_id_set_csv, for Google, et.al.)
      if $.isNumeric(item)
        catalog_items.push(item)
      # a set of zero or more IDs (ISBN, OCLC, or LCCN)
      standard_id_set_csv = res.attr('standard_ids')
      if (standard_id_set_csv)
        standard_id_sets.push(standard_id_set_csv)

  if fedora_items.length
    retrieve_fedora_resources(fedora_items)

  if catalog_items.length
    retrieve_holdings(catalog_items)

  if standard_id_sets.length
    retrieve_google_jackets(standard_id_sets)

  # if standard_id_sets.length
  #   retrieve_hathi_links(standard_id_sets)


@load_clio_holdings = (id) ->
  $("span.holding_spinner").show
  $("#clio_holdings .holdings_error").hide

  $.ajax
    url: '/backend/holdings/' + id

    success: (data) ->
        $('#clio_holdings').html(data)

    error: (data) ->
        $("span.holding_spinner").hide()
        $('#clio_holdings .holdings_error').show()

@load_hathi_holdings = (id) ->
  $(".hathi_holdings_check").show
  $(".hathi_holdings_error").hide

  $.ajax
    url: '/catalog/hathi_holdings/' + id

    success: (data) ->
        $('#hathi_data_wrapper').html(data)
        $('#hathi_holdings').show()

    error: (data) ->
        $(".hathi_holdings_check").hide()
        $('.hathi_holdings_error').show()
        $('#hathi_holdings').show()


@retrieve_fedora_resources = (fedora_ids) ->
  url = clio_backend_url + '/fedora/resources/' + fedora_ids.join('/');

  $.getJSON url, (data) ->
    for fedora_id, resources of data
      fedora_selector = '.fedora_' + fedora_id.replace(':','')
      $(fedora_selector).html('')
      first_resource = true

      # fix for NEXT-945 - Fedora non-PDF downloadable objects are given the PDF icon
      format_icons = [ "pdf", "ppt", "doc", "mp3", "mp4"]

      for i, resource of resources
        first_resource = false
        icon = "default"
        filename = resource['filename']
        if filename && filename.length > 3
          extension = filename.substr(filename.length - 3).toLowerCase()
          if $.inArray(extension, format_icons) >= 0
            icon = extension
        txt = '<div class="entry"><img src="/assets/format_icons/' + icon + '.png" width="16" height="16"/> <a href="' + resource['download_path'] + '">' + resource['filename'] + '</a></div>'
        $(fedora_selector).append(txt)

      if first_resource
        $(fedora_selector).html('No downloads found for this item.')


@retrieve_holdings = (bibids) ->
  url = clio_backend_url + '/holdings/status/' + bibids.join('/');


  $.getJSON url, (data) ->
    for bib, holdings of data
      for holding_id, status of data[bib].statuses
        selector = "img.availability.holding_" + holding_id
        status_upcase = status.charAt(0).toUpperCase() + status.slice(1)
        $(selector).attr("src", "/assets/icons/" + status + ".png")
        $(selector).attr("title", status_upcase)
        $(selector).attr("alt", status_upcase)


# Called from _google_books_check.html.haml, to update the
# Google section of the single-item Holdings information.
@update_google_holdings = (bibkeys, data) ->
  for index of bibkeys
    bibkey = bibkeys[index]
    bibkey_name = bibkey.replace(/:/, "")
    selector = $("img.bookjacket[src*='assets/spacer'].id_" + bibkey_name)
    bibkey_data = data[bibkey]

    if selector.length > 0 and bibkey_data
      selector.parents("#google_holdings").show()
      gbs_cover = selector.parents(".gbs_cover")

      if bibkey_data.thumbnail_url
        # the img is height 0, to not interfere with other elements.
        # reset to 'auto' before inserting GBS URL
        selector.height('auto')
        selector.attr "src", bibkey_data.thumbnail_url.replace(/zoom\=5/, "zoom=1")
        selector.parents(".book_cover").find(".fake_cover").hide()
        gbs_cover.show()

      $("li.gbs_info").show()
      $("a.gbs_info_link").attr "href", bibkey_data.info_url

      unless bibkey_data.preview is "noview"
        gbs_cover.find(".gbs_preview").show()
        gbs_cover.find(".gbs_preview_link").attr "href", bibkey_data.preview_url

        search_form = gbs_cover.find(".gbs_search_form")
        search_form.show()

        find_id = new RegExp("[&?]id=([^&(.+)=]*)").exec(bibkey_data.preview_url)
        strip_querystring = new RegExp("^[^?]+").exec(bibkey_data.preview_url)

        if find_id and strip_querystring
          search_form.attr("action", strip_querystring[0]).show()
          search_form.find("input[name=id]").attr "value", find_id[1]

        gbs_cover.find(".gbs_preview_partial").show()  if bibkey_data.preview is "partial"
        gbs_cover.find(".gbs_preview_full").show()  if bibkey_data.preview is "full"



@retrieve_google_jackets = (standard_id_sets) ->
  # console.log("TOTAL NUMBER OF SETS: " + standard_id_sets.length)
  for standard_id_set_csv in standard_id_sets
    # start_index = 0
    # standard_id_array = standard_id_set_csv.split(",")
    # retrieve_google_jacket_for_single_item(standard_id_array, start_index)
    retrieve_google_jacket_for_single_item_v2(standard_id_set_csv)


# @retrieve_google_jacket_for_single_item = (standard_id_array, start_index) ->
#   if start_index >= standard_id_array.length
#     return
# 
#   current_search_id = standard_id_array[start_index]
# 
#   # Google does not process ISSNs - skip over these, if present
#   if current_search_id.indexOf("issn") == 0
#     retrieve_google_jacket_for_single_item(standard_id_array, start_index + 1)
#     return
# 
#   # http://productforums.google.com/forum/#!topic/books-api/qDXTGnveQkc
#   # https://www.googleapis.com/books/v1/volumes?&q=isbn:0-521-51937-3
#   # https://www.googleapis.com/books/v1/volumes?q=lccn:2006921508
#   # https://www.googleapis.com/books/v1/volumes?q=oclc:70850767
#   # Google Books account for spectrum-tech@libraries.cul.columbia.edu
#   # API Key: AIzaSyDSEgQqa-dByStBpuRHjrFOGQoonPYs2KU
#   base_url = "https://www.googleapis.com/books/v1/volumes?"
#   base_url = base_url + "q=" + current_search_id.toUpperCase()
# 
#   # use an API key for non-anonymous tracked usage... but only after our
#   # API key has been allocated a very large quota
#   base_url = base_url + "&key=AIzaSyDSEgQqa-dByStBpuRHjrFOGQoonPYs2KU"
# 
#   $.getJSON(base_url, (data) ->
#     jacket_thumbnail_url = ''
#     if data && data.totalItems && data.totalItems > 0
# 
#       for google_item in data.items
#         if google_item.volumeInfo.imageLinks
#           # console.log("FOUND=" + base_url)
#           jacket_thumbnail_url = google_item.volumeInfo.imageLinks.thumbnail
#           standard_id_as_class = "id_" + current_search_id.replace(":","")
#           $('img.bookjacket.' + standard_id_as_class).attr('src', jacket_thumbnail_url)
#           return
#     if !jacket_thumbnail_url
#       # console.log("UNFOUND for " + current_search_id)
#       # recursive call, moving along to next identifier in the set
#       retrieve_google_jacket_for_single_item(standard_id_array, start_index + 1)
#   )

@retrieve_google_jacket_for_single_item_v2 = (standard_id_set_csv) ->
  # cribbed from: http://stackoverflow.com/questions/3839966
  # var tag = document.createElement("script");
  # tag.src = 'somewhere_else.php?callback=foo';
  # document.getElementsByTagName("head")[0].appendChild(tag);
  books_url = "http://books.google.com/books";
  api_url= books_url + "?jscmd=viewapi&bibkeys=" + standard_id_set_csv + "&callback=google_books_response_callback";
  tag = document.createElement("script")
  tag.src = api_url
  document.getElementsByTagName("head")[0].appendChild(tag)

# parse the response JSON from books.google.com, to extract the
# thumbnail URL to update the search results.
# see: https://developers.google.com/books/docs/dynamic-links
@google_books_response_callback = (data) ->
  for id, value_hash of data
    id_as_class = "id_" + id.replace(":","")
    if $('img.bookjacket.' + id_as_class) && value_hash.hasOwnProperty('thumbnail_url')
      $('img.bookjacket.' + id_as_class).attr('src', value_hash.thumbnail_url)
      return

  

# @retrieve_hathi_links = (standard_id_sets) ->
#   # console.log("HATHI:  TOTAL NUMBER OF SETS: " + standard_id_sets.length)
#   for standard_id_set_csv in standard_id_sets
#     start_index = 0
#     standard_id_array = standard_id_set_csv.split(",")
#     retrieve_hathi_links_for_single_item(standard_id_array, start_index)
# 
# 
# @retrieve_hathi_links_for_single_item = (standard_id_array, start_index) ->
#   if start_index >= standard_id_array.length
#     return
#   current_search_id = standard_id_array[start_index]
#   type_value = current_search_id.split(":")
#   id_type = type_value[0]
#   id_value = type_value[1]
#   base_url = "http://catalog.hathitrust.org/api/volumes/brief/"
#   base_url = base_url + id_type + "/" + id_value + ".json"
#   # not working yet.... XSS security errors...
#   # console.log("BASE_URL="+base_url)
#   # $.getJSON(base_url, (data) ->
#   #   console.log(data)
#   # )
# 




