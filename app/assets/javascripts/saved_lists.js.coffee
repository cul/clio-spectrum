# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->
  $('.item_select_checkbox').change ->
    if this.checked
      $(this).parents(".result.document").css('background-color', '#eee')
    else
      $(this).parents(".result.document").css('background-color', 'inherit')


@getSelectedItemKeyList = () ->
  item_key_array = $(".result.document").has('.item_select_checkbox:checked').map () -> $(this).attr('item_id')
  # turn array of jquery objects into array of item-id values
  item_key_array.get()

@selectAll = () ->
  $("#documents").find('.item_select_checkbox').prop('checked', true).change()

@deselectAll = () ->
  $("#documents").find('.item_select_checkbox').prop('checked', false).change()

# rewrite the "this" link so that the only CGI params are the current
# list of selected item keys
@appendSelectedToURL = (a_element) ->
  item_key_list = getSelectedItemKeyList()
  if item_key_list.length == 0
    flashMessage("notice", "No items selected") 
    return false
  item_keys_as_params = item_key_list.map ( item_key ) -> "id[]=" + item_key
  item_key_param_list = item_keys_as_params.join('&')
  _href = a_element.href.split("?")[0]
  a_element.href = _href + '?' + item_key_param_list
  return true

@XXXsaveSelectedToSavedList = () ->
  item_key_list = getSelectedItemKeyList()

  item_count = item_key_list.length || 0
  return flashMessage("notice", "No items selected") if item_count == 0
  success_message = item_count + " items saved to <a href='/lists'>Default List</a>"

  # Ajax to actually save the items...
  request = $.post '/lists/add', {item_key_list}
  request.done (data) -> flashMessage("success", success_message)
  request.fail (jqXHR, textStatus, errorThrown) -> flashMessage("error", "Save failed with " + textStatus + ": " + errorThrown)


@saveSelectedToNamedList = (name) ->
  item_key_list = getSelectedItemKeyList()
  item_count = item_key_list.length || 0
  success_message = item_count + " items saved to " + name

  # Ajax to actually save the items...
  request = $.post '/lists/add', {item_key_list, name}
  request.done (data) -> flashMessage("success", success_message)
  request.fail (jqXHR, textStatus, errorThrown) -> flashMessage("error", "Save failed with " + textStatus + ": " + errorThrown)


@removeSelectedFromList = (list_id) ->
  item_key_list = getSelectedItemKeyList()
  item_count = item_key_list.length || 0
  success_message = item_count + " items removed from list"

  # Ajax to actually remove the items...
  request = $.post '/lists/remove', {item_key_list, list_id}
  request.done (data) -> flashMessage("success", success_message)
  request.fail (jqXHR, textStatus, errorThrown) -> flashMessage("error", "Item removal failed with " + textStatus + ": " + errorThrown)
  


# status is one of the Bootstrap alert statuses:  error, success
@flashMessage = (status, message) ->
  # Blacklight's CSS sets display:none for button.close.  Override here.
  close_button = '<button type="button" class="close" data-dismiss="alert" style="display:block;">&times;</button>'
  flash_html_content = '<div class="alert alert-' + status + '">' + close_button + message + '</div>'
  $("div#main-flashes").append(flash_html_content)
  