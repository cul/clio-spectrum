class SavedListsController < ApplicationController
  include ActionView::Helpers::TextHelper

  # Devise protection...
  before_filter :authenticate_user!, except: [:show]
  before_filter :limited_show, only: [:show]

  layout 'no_sidebar'

  # Because we need "add_range_limit_params" when we lookup Solr records
  include LocalSolrHelperExtension


# INDEX is never called.  routes.rb redirects '/lists/' to show.
# Users are always viewing an active list, via show().
# If no list ID is passed, the default list is shown.
  # def index
  #   # Default index, show only your own lists
  #   @lists = List.where(:created_by => current_user.login)
  #
  #   respond_to do |format|
  #     format.html # index.html.erb
  #     format.json { render json: @lists }
  #   end
  # end


  def show
    # Determine search parameters to locate the list
    owner = params[:owner]
    slug  = params[:slug]  ||= SavedList::DEFAULT_LIST_SLUG

    # Default to your own lists, if you don't specify an owner
    if owner.blank? and current_user.present?
      owner = current_user.login
    end

    # # If request is for just "/lists", then MUST be logged in
    # if owner.blank? and current_user.blank?
    #   return redirect_to root_path,
    #                      flash: { error: 'Login required to access Saved Lists' }
    # end

    # logged-in users can see all their own lists.
    # loggin-in users can see anybody's public lists.
    # anonymous users can see anybody's public lists.
    if current_user.present? and owner == current_user.login
      # find one of my own lists
      @list = SavedList.find_by_owner_and_slug(owner, slug)
      # Special-case: if we're trying to pull up the user's default list,
      # auto-create it for them.
      if @list.blank? and slug == SavedList::DEFAULT_LIST_SLUG
        @list = SavedList.new(created_by: current_user.login,
                              owner: current_user.login,
                              name: SavedList::DEFAULT_LIST_NAME)
        @list.save!
      end
    else
      # find someone else's list
      if current_user.has_role?('site', 'admin')
        @list = SavedList.find_by_owner_and_slug(owner, slug)
      else
        @list = SavedList.find_by_owner_and_slug_and_permissions(owner, slug, 'public')
      end
    end

    if @list.blank?
      display_list_name = "#{owner}/#{slug}"
      return redirect_to root_path,
                         flash: { notice: "Cannot access list #{display_list_name}" }
    end

    # We have a list to display.
    # Turn the item-keys into full documents.
    item_key_array = @list.saved_list_items.order('updated_at').map { |item| item.item_key }
    @document_list = ids_to_documents(item_key_array)

    # The single-list "show" page will want to give a menu of all other lists
    @all_current_user_lists = []
    if current_user
      @all_current_user_lists = SavedList.where(owner: current_user.login).order('slug')
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @list }
    end
  end


# Lists are not "New"'d explicitly.
# Instead, items are added to a non-existant list name,
# which will automatically create the new list.
  # def new
  #   raise "don't use this method!"
  #   # @list = List.new(:created_by => current_user.login)
  #   @list = List.new()
  #
  #   respond_to do |format|
  #     format.html # new.html.erb
  #     format.json { render json: @list }
  #   end
  # end


  # GET /lists/1/edit
  def edit
    @list = SavedList.find_by_owner_and_id(current_user.login, params[:id])
    unless @list
      return redirect_to root_path,
                         flash: { error: 'Cannot access list' }
    end
  end


# Lists are not "Create"'d explicitly.
# Instead, items are added to a non-existant list name,
# which will automatically create the new list.
  # def create
  #   if current_user.blank?
  #     return redirect_to root_path,
  #       :flash => { :error => "Login required to access Saved Lists" }
  #   end
  #
  #   values = params[:list]
  #   values[:created_by] = current_user.login
  #   @list = SavedList.new(values)
  #
  #   respond_to do |format|
  #     if @list.save
  #       format.html { redirect_to @list, notice: 'List was successfully created.' }
  #       format.json { render json: @list, status: :created, location: @list }
  #     else
  #       format.html { render action: "new" }
  #       format.json { render json: @list.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end


  def update
    @list = SavedList.find_by_owner_and_id(current_user.login, params[:id])
    unless @list
      return redirect_to root_path,
                         flash: { error: 'Cannot access list' }
    end

    respond_to do |format|
      if @list.update_attributes(params[:saved_list])
        format.html { redirect_to @list.url, notice: 'List was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @list.errors, status: :unprocessable_entity }
      end
    end
  end


  def destroy
    @list = SavedList.find_by_owner_and_id(current_user.login, params[:id])
    unless @list
      return redirect_to root_path,
                         flash: { error: 'Cannot access list' }
    end

    @list.destroy

    respond_to do |format|
      format.html { redirect_to lists_path, notice: "List '#{@list.name}' deleted." }
      format.json { head :no_content }
    end
  end


  # Add items to a named list. (And Create the list if it does not yet exist)
  def add
    # # We're either passed a list of item-keys,
    # # OR we'll just add whatever's currently selected.
    # items_to_add = Array(params[:item_key_list] || session[:selected_items]).uniq

    # Try new approach - JS will have created a short-lived cookie with the ID(s) to add...
    items_to_add = Array(cookies[:items_to_add].split('/'))


    unless items_to_add
      render text: 'Must specify items to be added', status: :bad_request and return
    end

    list_name = params[:name] ||= SavedList::DEFAULT_LIST_NAME
    if list_name.empty?
      render text: 'Cannot add to unnamed list', status: :unprocessable_entity and return
    end

    # Find -- or CREATE -- a list with the right name
    @list = SavedList.where(owner: current_user.login, name: list_name).first
    unless @list
      @list = SavedList.new(created_by: current_user.login,
                            owner: current_user.login,
                            name: list_name)
      @list.save!
    end

    # redundant, move to model method
    # current_item_keys = @list.saved_list_items.map { |item| item.item_key }
    # 
    # new_item_adds = 0
    # (items_to_add - current_item_keys).each { |item_key|
    #   new_item = SavedListItem.new(item_key: item_key, saved_list_id: @list[:id])
    #   new_item.save!
    #   new_item_adds += 1
    #   @list.touch
    # }

    new_item_adds = @list.add_items_by_key(items_to_add)

    items_count = pluralize(items_to_add.size, 'item')

    # needless complexity
    # # Special message if everything we were asked to add is already there
    # if new_item_adds == 0
    #   render text: "#{items_count} already found in list #{view_context.link_to @list.name, @list.url}"
    #   return
    # end

    message = "#{items_count} added to list #{view_context.link_to @list.name, @list.url}".html_safe

    # # debug, override the above flash message with....
    # message = "items_to_add=[#{items_to_add}], class=[#{items_to_add.class}]"

    respond_to do |format|
      format.html { redirect_to after_sign_in_path_for, :flash => { :notice => message } }
      format.json { render text: message, status: :ok }
    end
  end


  # You MOVE your own items from list to list,
  # You COPY another user's items from their list to yours.
  def copy

    # We're either passed a list of item-keys,
    # OR we'll just add whatever's currently selected.
    items_to_add = Array(params[:item_key_list] || session[:selected_items]).uniq

     # To be sure about what we're doing, require the following params:
     # to_list       -- the Name of the destination list
     # item_key_list -- an array of item keys (bib keys or Summon FETCH ids)
    # unless params[:from_owner] && params[:from_list] && params[:to_list]
    unless params[:to_list]
      return redirect_to root_path,
                         flash: { error: 'Invalid input parameters - unspecified' }
    end

    # # Can't copy from a list to itself
    # if params[:from_list] == params[:to_list] &&
    #    params[:from_owner] == current_user.login
    #   return redirect_to root_path,
    #                      flash: { error: 'Invalid input parameters - cannot copy a list to itself' }
    # end

    #  # Fetch the source list, we'll need it's ID
    # if params[:from_owner] == current_user.login
    #   # Our own list
    #   from_list = SavedList.where(owner: current_user.login, name: params[:from_list]).first
    # else
    #   # Someone else's list - it must be public!
    #   from_list = SavedList.where(owner: params[:from_owner],
    #                               name: params[:from_list],
    #                               permissions: 'public').first
    # end

     # Find - or create - a destination list with the "to_list" Name
    @list = SavedList.where(owner: current_user.login, name: params[:to_list]).first
    unless @list
      @list = SavedList.new(owner: current_user.login,
                            name: params[:to_list])
      @list.save!
    end

    new_item_adds = @list.add_items_by_key(items_to_add)

    #  # List of what items are already in the list - don't add something twice!
    # current_item_keys = @list.saved_list_items.map { |item| item.item_key }
    # 
    #  # loop over the passed-in items, COPYING THEM to NEW saved-list-items
    # for item_key in Array.wrap(params[:item_key_list]) do
    #   next if current_item_keys.include? item_key
    #   item = SavedListItem.where(saved_list_id: from_list.id,
    #                              item_key: item_key).first
    #   unless item
    #     return redirect_to root_path,
    #                        flash: { error: "Item Key #{item_key} not found in #{params[:from_list]}" }
    #   end
    # 
    #   new_item = item.dup
    #   new_item.saved_list_id = @list.id
    #   new_item.save!
    # end

    redirect_to @list.url, notice: "#{params[:item_key_list].size} items copied to list #{view_context.link_to @list.name, @list.url}".html_safe
  end


  # You MOVE your own items from list to list,
  # You COPY another user's items from their list to yours.
  def move
    # We're either passed a list of item-keys,
    # OR we'll just add whatever's currently selected.
    items_to_add = Array(params[:item_key_list] || session[:selected_items]).uniq

    # To be sure about what we're doing, require the following params:
    # from_list     -- the Name of the source list
    # to_list       -- the Name of the destination list
    # item_key_list -- an array of item keys (bib keys or Summon FETCH ids)
    unless params[:from_owner] && params[:from_list] && params[:to_list]
      return redirect_to root_path,
                         flash: { error: 'Invalid input parameters - unspecified' }
    end

    # Can't copy from a list to itself
    if params[:from_list] == params[:to_list]
      return redirect_to root_path,
                         flash: { error: "Invalid input parameters - can't move list to itself" }
    end

    # move() is ONLY for moving items between your own lists
    if params[:from_owner] != current_user.login
      return redirect_to root_path,
                         flash: { error: 'Invalid input parameters - can only move your own items' }
    end


    # Implement "move" as "copy" followed by "delete"


    # Find - or create - a destination list with the "to_list" Name
    @list = SavedList.where(owner: current_user.login, name: params[:to_list]).first
    unless @list
      @list = SavedList.new(owner: current_user.login,
                            name: params[:to_list])
      @list.save!
    end

    new_item_adds = @list.add_items_by_key(items_to_add)


    # Fetch the source list, we'll need it's ID
    @from_list = SavedList.where(owner: current_user.login, name: params[:from_list]).first

    # loop over the passed-in items, set their owning list to Named list
    for item_key in Array(params[:item_key_list]) do
      item = SavedListItem.where(saved_list_id: @from_list.id,
                                 item_key: item_key).first
      unless item
        return redirect_to root_path,
                           flash: { error: "Item Key #{item_key} not found in #{params[:from_list]}" }
      end
      item.delete
    end

    redirect_to @list.url, notice: "#{params[:item_key_list].size} items moved to list #{view_context.link_to @list.name, @list.url}".html_safe
  end



  def remove
    unless params[:item_key_list]
      return redirect_to root_path,
                         flash: { error: 'Bad Request - no item keys passed' }
      # render :nothing => true, :status => :bad_request and return
    end

    # You have to own the list
    @list = SavedList.find_by_owner_and_id(current_user.login, params[:list_id])
    unless @list
      return redirect_to root_path,
                         flash: { error: 'Cannot access list' }
      # render :nothing => true, :status => :not_found and return
    end

    Array.wrap(params[:item_key_list]).each do |item_key|
      list_item = SavedListItem.find_by_item_key_and_saved_list_id(item_key, @list.id)
      if list_item && list_item.destroy
        @list.touch
      else
        return redirect_to root_path,
                           flash: { error: 'Unexpected error removing list items' }
        # render :nothing => true, :status => :internal_server_error and return
      end
    end

    # render :nothing => true, :status => :ok
    respond_to do |format|
      format.html { redirect_to @list.url, notice: "#{params[:item_key_list].size} items removed from list" }
    end
  end

  private

  def limited_show
    # If the 'owner' param is not passed, then require authentication
    authenticate_user! unless params[:owner]
  end

end
