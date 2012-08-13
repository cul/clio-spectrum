# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$(document).ready ->
  $('#database_alerts_maintain #search_box').submit ->
    url = '/admin/database_alerts/retrieve.js?' + $(this).children('form').serialize()
    $.getJSON url,  (data) ->

      results = $("#results")
      results.text("")
      results.children("#result_title").text("There were " + data.length + " results found.")
      for database in data
        id_prefix = 'alerts[' + database.clio_id + ']'


        result = $('<form/>', action: '/admin/database_alerts', method: 'post') 
        result.append(
          $('<input/>', {type: 'hidden', name: 'database_alert[clio_id]', value: database.clio_id}), 
          $('<div/>', {class: 'title', text: database.title}), 
          $('<div/>', {class: 'summary'}).append(
            $('<p/>', {text: database.summary})
            $('<p/>', {text: database.expanded_summary})
          )
        )

          
        if database.alerts 
          alert = database.alerts.database_alert
          updated = new Date(alert.updated_at)
          result.append($('<textarea/>', {name: 'database_alert[message]', text: alert.message}))
          result.append($('<div/>', text: 'Alert created by ' + alert.author.first_name + " " + alert.author.last_name + " at " + updated.toDateString()))
          result.append($('<button/>', class: 'btn-small', value: 'Update', text: 'Update'),
            $('<button/>', class: 'btn-small btn-danger', value: 'Delete', text: 'Delete'))
        else
          result.append($('<textarea/>', {name: 'database_alert[message]', placeholder: 'Enter an alert to display on this record'}))
          result.append($('<div/>').append(
            $('<button/>', class: 'btn-small', value: 'Create', text: 'Create')))


        result = $('<div/>', class: 'result').append(result)

        results.append(result)

     
    return false




  $('input[type=text]#search').attr("value", "physics")
  $('#search_box').submit()


