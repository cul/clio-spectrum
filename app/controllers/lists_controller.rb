# require 'blacklight/catalog'

class ListsController < ApplicationController
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
    
    if params[:id]
      @list = List.find(params[:id])
    elsif params[:login] && params[:name]
      @list = List.where(:created_by => params[:login], :name => params[:name]).first
    elsif params[:login]
      @list = List.where(:created_by => params[:login], :name => 'default').first
    end
        
    list_item_keys = @list.list_items.collect {|list_item| list_item[:item_key]}
    @response, @document_list = get_solr_response_for_field_values(SolrDocument.unique_key, list_item_keys)
    

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

  # DELETE /lists/add/234/456/789
  def add
    default_list = List.where(:created_by => current_user.login, :name => 'default').first
    unless default_list
      default_list = List.new(:created_by => current_user.login, :name => 'default')
      default_list.save
    end
    for item_key in params[:id].split('/') do
      new_item = ListItem.new(:item_key => item_key, :list_id => default_list[:id])
      new_item.save
    end
    
    redirect_to :action => 'index'
  end
  
end
