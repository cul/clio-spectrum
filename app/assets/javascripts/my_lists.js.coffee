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



@saveSelectedToMyList = () ->
  item_key_list = getSelectedItemKeyList()

  item_count = item_key_list.length || 0
  success_message = item_count + " items saved to <a href='/mylist'>My List</a>"

  # Ajax to actually save the items...
  request = $.post '/mylist/add', {item_key_list}
  request.done (data) -> flashMessage("success", success_message)
  request.fail (jqXHR, textStatus, errorThrown) -> flashMessage("error", "Save failed with " + textStatus + ": " + errorThrown)


  

# status is one of the Bootstrap alert statuses:  error, success
@flashMessage = (status, message) ->
  # Blacklight's CSS sets display:none for button.close.  Override here.
  close_button = '<button type="button" class="close" data-dismiss="alert" style="display:block;">&times;</button>'
  flash_html_content = '<div class="alert alert-' + status + '">' + close_button + message + '</div>'
  $("div#main-flashes").append(flash_html_content)
  