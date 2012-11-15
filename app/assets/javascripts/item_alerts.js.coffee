# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
#

$ ->
  $('#show_alert_management .add_row_button').click -> 
    $('#create_alert').fadeIn()
    $(this).parents('tr').hide()

  $('#show_alert_management .delete-item').click ->
    if (confirm('Are you sure you want to delete this alert?'))
      button = this
      $.ajax(
        url: $(button).attr('data-delete')
        type: 'DELETE'
        dataType: 'json'
        success: (data, textStatus, jqXHR) ->
          $(button).parents('tr').remove() 
      )
        

  $('#show_alert_management form').submit ->
    form = $(this)
    $.ajax(
      url: form.attr('action')
      data: form.serialize()
      type: 'POST'
      dataType: 'json'
      success: (data, textStatus, jqXHR) ->
        response = JSON.parse(jqXHR.responseText)
        item = response.item_alert
        row = $(form).children('tr[data-id=' + item.id + ']')
        $.get('/item_alerts/' + item.id + '/show_table_row', (data) ->
          if row.length == 0
            
            $('#create_alert').fadeOut()
            $('#show_alert_management table').append(data)
        )
      error: (data, textStatus, jqXHR) ->
        alerts = form.find('.alerts')
        alerts.empty()
  
        alert_html = "<div class='alert alert-error'><btn class='close' type='button' data-dismiss='alert'>x</btn>There are errors with your submission.<ul>"

        response = JSON.parse(data.responseText)
        for field,errors of response
          for error in errors
            alert_html += '<li>' + field + " " + error + "</li>"

        alert_html += "</ul></div>"
        form.find('.alerts').html(alert_html)
    )

    return false

