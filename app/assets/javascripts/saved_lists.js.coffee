

$ ->


  # Clicking the "Add to My List" link should post to SavedListsController.add()
  # Follow advice from:
  #   http://stackoverflow.com/questions/133925/javascript-post-request
  # 
  # N.B. - We don't want POST params, because those will get lost as we bounce
  # through Shibboleth authentication.  
  # And, We don't want GET params, because those stick around in the history,
  # and may inadvertently be re-played by users doing back,back,back.
  # Instead ALL params need to come from cookies/session.
  # 
  # We're using session[:selected_items] for now.  But there's some confusion
  # between wanting on-screen item-selections and state-preservation through
  # the ADD process - especially on single-item views.
  # 
  # Switch to a simple short-lived cookie, "items_to_add".
  # We'll populate this just-in-time, and clear it immediately after use.
  # 
  $('.saved_list_add').click ->
  
    # Does the clicked object have 'data-identifier'?
    identifier = $(this).data("identifier")

    if typeof(identifier) == "undefined"
      # If there's no identifier, process any current DOM selected items
      items_to_add = getSelectedItemKeyList().join('/')
    else
      # If there is an identifier, process that single item
      items_to_add = identifier

    
    if typeof(items_to_add) == "undefined" || items_to_add.length < 1
      flashMessage("danger", "No items selected") 
      return false


    # Build a 5-minute cookie, to be read by the form-target
    date = new Date
    date.setTime(date.getTime() + (100*5*60*1000))
    expires = '; expires=' + date.toGMTString()
    document.cookie = 'items_to_add=' + items_to_add + expires + '; path=/'

    # alert(items_to_add)

    form = document.createElement("form")
    form.setAttribute("method", "POST")
    form.setAttribute("action", "/lists/add")
    document.body.appendChild(form)
    form.submit()
  
  # To support persistent selected items, without muddling into the
  # view partials, fire off some javascript to style any checked items
  # at page load.
  $('.item_select_checkbox:checked').parents(".result.document").addClass('selected_item')

  # After the html page has rendered, reset the Rails session persistent
  # selected item list to only what's currently displayed on screen.
  resetSelectedItemsList()

  # This handler fires when the user clicks the item-select checkbox,
  # OR when the object's "checked" property is modified by JavaScript
  $('.item_select_checkbox').change ->
    # Apply/remove the 'selected_item' style - controls Coloring only
    $(this).parents(".result.document").toggleClass('selected_item', this.checked)

  # This part fires ONLY on real-user clicks
  # Fire-off AJAX to add/remove from Rails session storage
  $('.item_select_checkbox').click ->

    # Fetch the item-identifier
    identifier = $(this).data("identifier");
    if typeof(identifier) == "undefined"
      flashMessage("danger", "Selected item has no identifier?") 
      return false
    
    # Add/Remove from the persistent selected-item list
    if this.checked
      setSelectedItems("add", identifier)
    else
      setSelectedItems("remove", identifier)



# AJAX manipulation of persistent selected-item list.
# Add or remove a single identifier, or clear the list,
# or reset the list to a specific list of ids.
@setSelectedItems = (verb, id_param) ->
  request = $.post "/selected_items", { verb, id_param }
  # Do nothing if successful - don't flash
  # request.done (data) -> flashMessage("success", data)
  # Alert if problem
  request.fail (jqXHR, textStatus, errorThrown) -> flashMessage("danger", "Select failed: " + errorThrown + "  " + jqXHR.responseText)


@resetSelectedItemsList = () ->
  item_key_list = getSelectedItemKeyList()
  if item_key_list.length > 0
    setSelectedItems("reset", item_key_list)


@selectAll = () ->
  $("#documents").find('.item_select_checkbox').prop('checked', true).change()
  item_key_list = getSelectedItemKeyList()
  setSelectedItems("reset", item_key_list)

@deselectAll = () ->
  $("#documents").find('.item_select_checkbox').prop('checked', false).change()
  setSelectedItems("clear")



# Fetch items currently in the DOM with their 'selected' checkbox in Checked state.
# (There may be more items in session[:selected_items] that are not displayed on the current page)
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
  # add 'rows' param, so we don't default to 25 max
  rows_param = '&rows=' + item_key_list.length
  a_element.href = _href + '?' + item_key_param_list + rows_param
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
  full_move_url = savedlist_move_path + "?from_owner=" + from_owner + "&from_list=" + encodeURIComponent(from_list) + "&to_list=" + encodeURIComponent(to_list) + "&" + $.param( { 'item_key_list': item_key_list } )
  window.location.href = full_move_url

# Non-AJAX - copy list of item-keys to named list,
# bounce user to the new list view page
@copySelectedToNamedList = (savedlist_copy_path, from_owner, from_list, to_list) ->
  item_key_list = getSelectedItemKeyList()
  if item_key_list.length == 0
    flashMessage("notice", "No items selected") 
    return false
  full_copy_url = savedlist_copy_path + "?from_owner=" + from_owner + "&from_list=" + encodeURIComponent(from_list) + "&to_list=" + encodeURIComponent(to_list) + "&" + $.param( { 'item_key_list': item_key_list } )
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
  # Re-map Rails flash types to Bootstrap style types as needed...
  if status == 'notice'    
    status = 'info';
  if status = 'error'      
    status = 'danger';
  # Blacklight's CSS sets display:none for button.close.  Override here.
  close_button = '<button type="button" class="close" data-dismiss="alert" style="display:block;">&times;</button>'
  flash_html_content = '<div class="alert alert-' + status + '">' + close_button + message + '</div>'
  $("div#main-flashes div.flash_messages").append(flash_html_content)


