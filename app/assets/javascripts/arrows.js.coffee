
# Listen for left-arrow / right-arrow to go to 'Previous' or 'Next'

$ ->
	
	# Search Results (catalog index)
  if ($('div.page_links').is(":visible"))
    $(document).keydown (e) ->
      if e.which == 37
        # left     
        $('div.page_links a[rel="prev"]')[0].click()
      else if e.which == 39
        # right     
        $('div.page_links a[rel="next"]')[0].click()
      return


	# Item Detail (catalog show)
  if ($('#search_info.navbar-text').is(":visible"))
    $(document).keydown (e) ->
      if e.which == 37
        # left     
        $('#search_info.navbar-text a[rel="prev"]')[0].click()
      else if e.which == 39
        # right     
        $('#search_info.navbar-text a[rel="next"]')[0].click()
      return



