
@OpenTextMessage = (bibid) ->
  url = 'http://www.columbia.edu/cgi-bin/cul/forms/text?' + bibid
  OpenWindow(url)

@OpenInprocessRequest = (bibid) ->
  url = 'https://www1.columbia.edu/sec-cgi-bin/cul/forms/inprocess?' + bibid
  OpenWindow(url)

@OpenSearchRequest = (bibid) ->
  url = 'https://www1.columbia.edu/sec-cgi-bin/cul/forms/search?' + bibid
  OpenWindow(url)

@OpenPrecatRequest = (bibid) ->
  url = 'https://www1.columbia.edu/sec-cgi-bin/cul/forms/precat?' + bibid
  OpenWindow(url)

@OpenItemFeedback = (bibid) ->
  url = 'https://www1.columbia.edu/sec-cgi-bin/cul/forms/itemfeedback?' + bibid
  OpenWindow(url)

# @OpenValet = (bibid, valet_url) ->
#   url = valet_url + bibid
#   OpenWindow(url)

@OpenURL = (bibid, url) ->
  full_url = url + bibid
  OpenWindow(full_url)

@OpenWindow = (url) ->
  window.open(url,'','left=200,top=200,width=650,height=700,scrollbars')
  return false
