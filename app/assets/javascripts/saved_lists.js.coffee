
$ ->

  # Clicking the "Add to My List" link should post to SavedListsController.add()
  # Follow advice from:
  #   http://stackoverflow.com/questions/133925/javascript-post-request
  $('.saved_list_add').click ->
    form = document.createElement("form")
    form.setAttribute("method", "POST")
    form.setAttribute("action", "/lists/add")
    
    # for(var key in params) {
    #     if(params.hasOwnProperty(key)) {
    #         var hiddenField = document.createElement("input");
    #         hiddenField.setAttribute("type", "hidden");
    #         hiddenField.setAttribute("name", key);
    #         hiddenField.setAttribute("value", params[key]);
    #         form.appendChild(hiddenField);
    #      }
    # }

    document.body.appendChild(form)
    form.submit()
  
  
  # To support persistent selected items, without muddling into the
  # view partials, fire off some javascript to style any checked items
  # at page load.
  $('.item_select_checkbox:checked').parents(".result.document").addClass('selected_item')

  # This handler fires when the user clicks the item-select checkbox,
  # OR when the object's "checked" property is modified by JavaScript
  $('.item_select_checkbox').change ->

    # Fetch the item-identifier
    identifier = $(this).data("identifier");
    if typeof(identifier) == "undefined"
      flashMessage("danger", "Selected item has no identifier?") 
      return false
    
    # Apply/remove the 'selected_item' style - controls Coloring only
    $(this).parents(".result.document").toggleClass('selected_item', this.checked)
    
    # Add/Remove from the persistent selected-item list
    if this.checked
      setSelectedItems("add", identifier)
    else
      setSelectedItems("remove", identifier)

# AJAX manipulation of persistent selected-item list.
# Add or remove a single identifier, or clear the list.
@setSelectedItems = (verb, identifier) ->
  request = $.post "/selected_items", { verb, identifier }
  - # Do nothing if successful
  - # request.done (data) -> flashMessage("success", data)
  - # Alert if problem
  request.fail (jqXHR, textStatus, errorThrown) -> flashMessage("danger", "Select failed: " + errorThrown + "  " + jqXHR.responseText)









@selectAll = () ->
  $("#documents").find('.item_select_checkbox').prop('checked', true).change()

@deselectAll = () ->
  $("#documents").find('.item_select_checkbox').prop('checked', false).change()




@getSelectedItemKeyList = () ->
  item_key_array = $(".result.document").has('.item_select_checkbox:checked').map () -> $(this).attr('item_id')
  # turn array of jquery objects into array of item-id values
  item_key_array.get()


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

# AJAX - add list of item-keys to named list
@saveSelectedToNamedList = (name) ->
  item_key_list = getSelectedItemKeyList()
  if item_key_list.length == 0
    flashMessage("notice", "No items selected") 
    return false
  # item_count = item_key_list.length || 0
  # success_message = item_count + " items saved to " + name
  saveItemListToNamedList(item_key_list, name)

@saveBibToNamedList = (bib, name) ->
  item_key_list = [bib]
  saveItemListToNamedList(item_key_list, name)

@saveItemListToNamedList = (item_key_list, name) ->
  # Ajax to actually save the items...
  request = $.post '/lists/add', { item_key_list, name }
  request.done (data) -> flashMessage("success", data)
  request.fail (jqXHR, textStatus, errorThrown) -> flashMessage("danger", "Save failed: " + errorThrown + "  " + jqXHR.responseText)


# Non-AJAX - move list of item-keys to named list,
# bounce user to the new list view page
@moveSelectedToNamedList = (savedlist_move_path, from_owner, from_list, to_list) ->
  item_key_list = getSelectedItemKeyList()
  if item_key_list.length == 0
    flashMessage("notice", "No items selected") 
    return false
  full_move_url = savedlist_move_path + "?from_owner=" + from_owner + "&from_list=" + from_list + "&to_list=" + to_list + "&" + $.param( { 'item_key_list': item_key_list } )
  window.location.href = full_move_url

# Non-AJAX - copy list of item-keys to named list,
# bounce user to the new list view page
@copySelectedToNamedList = (savedlist_copy_path, from_owner, from_list, to_list) ->
  item_key_list = getSelectedItemKeyList()
  if item_key_list.length == 0
    flashMessage("notice", "No items selected") 
    return false
  full_copy_url = savedlist_copy_path + "?from_owner=" + from_owner + "&from_list=" + from_list + "&to_list=" + to_list + "&" + $.param( { 'item_key_list': item_key_list } )
  window.location.href = full_copy_url

# Non-AJAX remove items from list
@removeSelectedFromList = (savedlist_remove_path, list_id) ->
  item_key_list = getSelectedItemKeyList()
  if item_key_list.length == 0
    flashMessage("notice", "No items selected") 
    return false
  full_remove_url = savedlist_remove_path + "?list_id=" + list_id + "&" + $.param( { 'item_key_list': item_key_list } )
  # alert(full_remove_url)
  window.location.href = full_remove_url 


# status is one of the Bootstrap alert statuses:  error, success
@flashMessage = (status, message) ->
  # Blacklight's CSS sets display:none for button.close.  Override here.
  close_button = '<button type="button" class="close" data-dismiss="alert" style="display:block;">&times;</button>'
  flash_html_content = '<div class="alert alert-' + status + '">' + close_button + message + '</div>'
  $("div#main-flashes").append(flash_html_content)


