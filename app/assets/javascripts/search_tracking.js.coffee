$ ->
  $('.search_box button.submit').click ->
    try
      identifier = BlacklightGoogleAnalytics.this_or_parent_id($(this))
      selected_option =  $(this).parent().find('select.search_field option:selected')
      if selected_option.attr('value')
        action = selected_option.attr('value')
      else 
        action = 'all_fields'
      label = $(this).parent().children('input.q').attr('value')
      _gaq.push(['_trackEvent', identifier, action, label])

    catch err
      BlacklightGoogleAnalytics.console_log_error(err, [identifier, action, label])

    BlacklightGoogleAnalytics.pause()

  $('.result a[data-counter]').click ->
    try
      identifier = 'document_click'
      action = 'title'
      label = $(this).attr('data-counter')
      _gaq.push(['_trackEvent', identifier, action, 'item', label])

    catch err
      BlacklightGoogleAnalytics.console_log_error(err, [identifier, action, label])

    BlacklightGoogleAnalytics.pause()
