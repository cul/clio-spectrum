


$ ->
  q = $('#best_bets_query').data('query')
  if typeof q != 'undefined'
    $.get('/best_bets/hits?q=' + q, (data) ->
	    if data.length > 0
        $('#best_bets_hits').append(data)
        $('#best_bets_hits').slideDown(1000)
	  )
# $('#best_bets').appendChild(data)
#     hit_span.html(data)
#   )
# 
# if 
# 
# $.ajax
#   url: '/best_bets?q=' + 
# 
#   success: (data) ->
#       $('#hathi_data_wrapper').html(data)
#       $('#hathi_holdings').show()
#       # If we have a long list of holdings,
#       # they'll be rendered with collapse/expand.
#       $(".expander").click ->
#         $('#hathi_holdings').find(".expander").hide()
#         $('#hathi_holdings').find(".expander_more").removeClass('expander_more')
# 
#   error: (data) ->
#       $(".hathi_holdings_check").hide()
#       $('.hathi_holdings_error').show()
#       $('#hathi_holdings').show()
# 
# $('.result_set.async_result_set').each ->
#   result_set = $(this)
#   url = result_set.attr('data-result-set')
#   $.get(url, (data) ->
#     result_set.html(data)
#     # re-activate popovers on the re-written html:
#     $("a[rel='popover']").popover()
#     async_lookup_item_details(result_set)
#     async_fill_in_hit_count(result_set)
#   )

