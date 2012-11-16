# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
#
bind_datepickers = () -> 
	$("input[data-datepicker-format]").datepicker(
		weekStart: 1
		days: ["S","M","T","W","T","F","S"]
		months: ["January","February","March","April","May","June","July","August","September","October","November","December"]
  )

bind_alert_management_buttons = (alert_div) ->

  $(alert_div).find('.edit-item').click ->
    row = $(this).parents('tr')
    button = $(this)
    $.ajax(
      url: $(button).attr('data-modify')
      type: 'GET'
      dataType: 'script'
      complete: (jqXHR, textStatus) ->
        if jqXHR.statusText == "OK"
          new_row = $("<tr data-id='" + row.attr('data-id') + "'><td colspan='5'><div class='edit_form' data-id='" + row.attr('data-id') + "'>" + jqXHR.responseText + "</div></td></tr>")
          row.after(new_row)
          row.hide()
          bind_datepickers()
          bind_alert_management_form($('#show_alert_management form'))
          new_row.find('div.edit_form').fadeIn()
    )

  $(alert_div).find('.delete-item').click ->
    if (confirm('Are you sure you want to delete this alert?'))
      button = this
      $.ajax(
        url: $(button).attr('data-delete')
        type: 'DELETE'
        dataType: 'json'
        success: (data, textStatus, jqXHR) ->
          $(button).parents('tr').remove() 
      )

bind_alert_management_form = (form) ->
  $('#show_alert_management form').submit ->
    form = $(this)
    parent_div = form.parent()
    parent_row = form.parents('tr')
    $.ajax(
      url: form.attr('action')
      data: form.serialize()
      type: 'POST'
      dataType: 'json'
      success: (data, textStatus, jqXHR) ->
        item_id = parent_div.attr('data-id')
        if item_id == undefined
          response = JSON.parse(jqXHR.responseText)
          item = response.item_alert
          item_id = item.id
        item_id_selector = 'tr[data-id=' + item_id + ']'
        row = $(item_id_selector)
        $.get('/item_alerts/' + item_id + '/show_table_row', (data) ->

          parent_div.fadeOut()
          add_row = $('#show_alert_management .add_row_button').parents('tr')
          
          if row.length == 0
            form.find('input[type=text],textarea').each ->
              $(this).val('')
            $('#show_alert_management table').append(data)
          else
            parent_row.after(data)
            parent_row.remove()

          $('#show_alert_management table').append(add_row)
          bind_alert_management_buttons(item_id_selector)
          add_row.show()

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

$ ->
  $('#show_alert_management .add_row_button').click -> 
    $('#create_alert').fadeIn()
    $(this).parents('tr').hide()

        

  bind_alert_management_buttons('#show_alert_management')
  bind_alert_management_form($('#show_alert_management form'))
  bind_datepickers()
