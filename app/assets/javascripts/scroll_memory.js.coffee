

# http://stackoverflow.com/questions/12744145/how-to-remember-scroll-position-o-page

$ ->

  # When the user clicks a "link_back", store an indicator that
  # the subsequent page should go to the scroll position.
  $('.link_back').click ->
    window.localStorage['goto_scroll'] = true
    # And, mark the bib we're on, so it can be highlighted in the list
    if $(this).data('bib')
      window.localStorage['highlight_bib'] = $(this).data('bib')

  # Look to see if this is a page which supports scroll memory...
  if $('.scroll_memory').length
    # alert window.location.pathname + " has scroll memory"

    # Every time we scroll, record the new scroll position
    $(document).scroll ->
      # alert 'saving scroll position: ' + $(document).scrollTop()
      window.localStorage['scroll'] = $(document).scrollTop()

    # Look to see if the "goto scroll" indicator is set.
    # If it is, try to restore a previous scroll position.
    if typeof( window.localStorage['scroll'] ) != 'undefined'
      if typeof( window.localStorage['goto_scroll'] ) != 'undefined'
        localStorage.removeItem('goto_scroll')
        $(document).scrollTop( window.localStorage['scroll'] )

    # Look to see if we've been told to highlight a particular record
    # If so, try to flash it (and remove the indicator)
    if typeof( window.localStorage['highlight_bib'] ) != 'undefined'
      localStorage.removeItem('highlight_bib')
      # flash the bib... how?
      
       

