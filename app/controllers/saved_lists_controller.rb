# require 'blacklight/catalog'

class SavedListsController < ApplicationController
  layout "no_sidebar"

  include ApplicationHelper

  include LocalSolrHelperExtension
  include SavedListsHelper
  # include Blacklight::Catalog
  # include Blacklight::Configurable


  # GET /lists
  # GET /lists.json
  def index
    # Default index, show only your own lists
    @lists = List.where(:created_by => current_user.login)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @lists }
    end
  end

  # GET /lists/1
  # GET /lists/1.json
  def show

    # Determine search parameters to locate the list
    owner = params[:owner]
    slug  = params[:slug]  ||= "default"

    # Default to your own lists, if you don't specify an owner
    if owner.blank? and current_user.present?
      owner = current_user.login
    end

    # If request is for just "/mylist", then MUST be logged in
    if owner.blank? and current_user.blank?
      return redirect_to root_path,
        :flash => { :error => "Login required to access Saved Lists" }
    end

    # logged-in users can see all their own lists.
    # loggin-in users can see anybody's public lists.
    # anonymous users can see anybody's public lists.
    if current_user.present? and owner == current_user.login
      # find one of my own lists
      @list = SavedList.find_by_owner_and_slug(owner, slug)
    else
      # find someone else's list
      @list = SavedList.find_by_owner_and_slug_and_permissions(owner, slug, "public")
    end

    if @list.blank?
      display_list = ''
      display_list += "/#{params[:owner]}" if params[:owner].present?
      display_list += "/#{params[:slug]}" if params[:slug].present?
      return redirect_to root_path,
        :flash => { :error => "Cannot access list #{display_list}" }
    end

    # We have a list to display.
    # Turn the item-keys into full documents.
    item_key_array = @list.saved_list_items.order("updated_at").collect { |item| item.item_key }
    @document_list = ids_to_documents( item_key_array )

    # catalog_item_keys = []
    # articles_item_keys = []
    # @list.saved_list_items.each do |list_item|
    #   catalog_item_keys.push list_item[:item_key] if
    #     list_item[:item_source] == 'catalog'
    #   articles_item_keys.push list_item[:item_key] if
    #     list_item[:item_source] == 'articles'
    # end
    # 
    # @response, @catalog_document_list = get_solr_response_for_field_values(SolrDocument.unique_key, catalog_item_keys)
    # 
    # @article_document_list = get_summon_docs_for_id_values(articles_item_keys)
    # 
    # # merge the two document lists - in saved_list_item order...

    # The single-list "show" page will want to give a menu of all other lists
    @all_current_user_lists = []
    if current_user
      @all_current_user_lists = SavedList.where(:owner => current_user.login).order("slug")
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @list }
    end
  end

  # GET /lists/new
  # GET /lists/new.json
  def new
    # @list = List.new(:created_by => current_user.login)
    @list = List.new()

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @list }
    end
  end

  # GET /lists/1/edit
  def edit
    if current_user.blank?
      return redirect_to root_path,
        :flash => { :error => "Login required to access Saved Lists" }
    end

    @list = SavedList.find_by_owner_and_id(current_user.login, params[:id])
    unless @list
      return redirect_to root_path,
        :flash => { :error => "Cannot access list" }
    end

  end

  # POST /lists
  # POST /lists.json
  def create
    if current_user.blank?
      return redirect_to root_path,
        :flash => { :error => "Login required to access Saved Lists" }
    end

    values = params[:list]
    values[:created_by] = current_user.login
    @list = List.new(values)

    respond_to do |format|
      if @list.save
        format.html { redirect_to @list, notice: 'List was successfully created.' }
        format.json { render json: @list, status: :created, location: @list }
      else
        format.html { render action: "new" }
        format.json { render json: @list.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /lists/1
  # PUT /lists/1.json
  def update
    if current_user.blank?
      return redirect_to root_path,
        :flash => { :error => "Login required to access Saved Lists" }
    end

    @list = SavedList.find_by_owner_and_id(current_user.login, params[:id])
    unless @list
      return redirect_to root_path,
        :flash => { :error => "Cannot access list" }
    end

    respond_to do |format|
      if @list.update_attributes(params[:saved_list])
        format.html { redirect_to @list.url, notice: 'List was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @list.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /lists/1
  # DELETE /lists/1.json
  def destroy
    if current_user.blank?
      return redirect_to root_path,
        :flash => { :error => "Login required to access Saved Lists" }
    end

    @list = SavedList.find_by_owner_and_id(current_user.login, params[:id])
    unless @list
      return redirect_to root_path,
        :flash => { :error => "Cannot access list" }
    end

    @list.destroy

    respond_to do |format|
      format.html { redirect_to mylist_path }
      format.json { head :no_content }
    end
  end

  # GET /my_lists/add/234
  # POST /my_lists/add
  # This is called via ajax - return success/failure, but no html content.
  # Create the named list if it does not yet exist
  def add

    # You have to be logged in to use this feature
    if current_user.blank?
      render :nothing => true, :status => :unauthorized and return
    end

    list_name = params[:name] ||= "default"

    the_list = SavedList.where(:owner => current_user.login, :name => list_name).first
    unless the_list
      the_list = SavedList.new(:owner => current_user.login, :name => list_name)
      the_list.save
    end
# logger.warn "=========tl #{the_list.inspect}"
    current_item_keys = the_list.saved_list_items.map{ |item| item.item_key }
# logger.warn "=========cik #{current_item_keys.inspect}"

    for item_key in Array.wrap(params[:item_key_list]) do
      next if current_item_keys.include? item_key
# logger.warn "=========ik #{item_key.inspect}"

      new_item = SavedListItem.new(:item_key => item_key, :saved_list_id => the_list[:id])
      new_item.save
      the_list.touch
    end

    render :nothing => true, :status => :ok
  end


  # request = $.post '/mylist/remove', {item_key_list, list_id}
  def remove
    # You have to be logged in to use this feature
    if current_user.blank?
      render :nothing => true, :status => :unauthorized and return
    end

    # You have to own the list
    @list = SavedList.find_by_owner_and_id(current_user.login, params[:list_id])
    unless @list
      render :nothing => true, :status => :not_found and return
    end

    Array.wrap(params[:item_key_list]).each do |item_key|
      list_item = SavedListItem.find_by_item_key_and_saved_list_id(item_key, @list.id)
      if list_item.destroy
        @list.touch
      else
        render :nothing => true, :status => :internal_server_error and return
      end
    end

    render :nothing => true, :status => :ok

  end

end
