# require 'blacklight/catalog'

class MyListsController < ApplicationController
  layout "no_sidebar_no_search"

  include LocalSolrHelperExtension
  # include Blacklight::Catalog
  # include Blacklight::Configurable
  # include BlacklightUnapi::ControllerExtension
  
  
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
      @list = MyList.find_by_owner_and_slug(owner, slug)
    else
      # find someone else's list
      @list = MyList.find_by_owner_and_slug_and_permissions(owner, slug, "public")
    end

    if @list.blank?
      display_list = ''
      display_list += "/#{params[:owner]}" if params[:owner].present?
      display_list += "/#{params[:slug]}" if params[:slug].present?
      return redirect_to root_path, 
        :flash => { :error => "Cannot access list #{display_list}" }
    end
    
    list_item_keys = @list.my_list_items.collect { |list_item|
      list_item[:item_key]
    }
    @response, @document_list = get_solr_response_for_field_values(SolrDocument.unique_key, list_item_keys)
    
    @all_user_lists = []
    if current_user.present?
      @all_user_lists = MyList.where(:owner => current_user.login)
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
    @list = List.find(params[:id])
  end

  # POST /lists
  # POST /lists.json
  def create
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
    @list = List.find(params[:id])

    respond_to do |format|
      if @list.update_attributes(params[:list])
        format.html { redirect_to @list, notice: 'List was successfully updated.' }
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
    @list = List.find(params[:id])
    @list.destroy

    respond_to do |format|
      format.html { redirect_to lists_url }
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
    
    the_list = MyList.where(:owner => current_user.login, :name => list_name).first
    unless the_list
      the_list = MyList.new(:owner => current_user.login, :name => list_name)
      the_list.save
    end
# logger.warn "=========tl #{the_list.inspect}"
    current_item_keys = the_list.my_list_items.map{ |item| item.item_key }
# logger.warn "=========cik #{current_item_keys.inspect}"
    
    for item_key in Array.wrap(params[:item_key_list]) do
      next if current_item_keys.include? item_key
# logger.warn "=========ik #{item_key.inspect}"

      new_item = MyListItem.new(:item_key => item_key, :my_list_id => the_list[:id])
      new_item.save
    end
    
    render :nothing => true, :status => :ok
  end
  
end
