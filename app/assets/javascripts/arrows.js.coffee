
# Listen for left-arrow / right-arrow to go to 'Previous' or 'Next'

# This is unreliable - our test to see if any input element has
# focus is not always accurate.  Turn this all off for now.

# $ ->
# 
#   # Any keydown event
#   $(document).keydown (e) ->
# 
#     # If any modifier key is down don't handle the keypress
#     if e.metaKey || e.altKey || e.ctrlKey || e.shiftKey
#       return
# 
#     # If we're focused on any input box don't handle the keypress 
#     if $('input:focus').length > 0
#       return
# 
#     # Pagination through facet values
#     if ($('div.prev_next_links').is(":visible"))
#       if e.which == 37
#         # left     
#         $('div.prev_next_links a[rel="prev"]')[0].click()
#       else if e.which == 39
#         # right     
#         $('div.prev_next_links a[rel="next"]')[0].click()
#       return
# 
#     # If Blacklight's AJAX Modal is open, don't handle keypress
#     if $('#ajax-modal').is(':visible')
#       return
# 
#     # Search Results (catalog index)
#     if ($('div.page_links').is(":visible"))
#       if e.which == 37
#         # left     
#         $('div.page_links a[rel="prev"]')[0].click()
#       else if e.which == 39
#         # right     
#         $('div.page_links a[rel="next"]')[0].click()
#       return
# 
#     # Item Detail (catalog show)
#     if ($('#search_info.navbar-text').is(":visible"))
#       $(document).keydown (e) ->
#         if e.which == 37
#           # left     
#           $('#search_info.navbar-text a[rel="prev"]')[0].click()
#         else if e.which == 39
#           # right     
#           $('#search_info.navbar-text a[rel="next"]')[0].click()
#         return
# 
# 
# 
