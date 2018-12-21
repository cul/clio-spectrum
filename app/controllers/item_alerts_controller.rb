# ItemAlerts are messages about access-restrictions, outages, etc..
#
# They are authored by a restricted set of authorized users, and are
# attached to a particular item-id, with a start- and end- time.
#
# The item-id does not have to be a Voyager ID.  Item Alerts are in
# theory applicable to non-catalog datasources.
class ItemAlertsController < ApplicationController
  check_authorization
  load_and_authorize_resource except: :create

  before_action :authenticate_user!
  layout 'no_sidebar'

  # GET /item_alerts
  # GET /item_alerts.json
  def index
    authorize! :read, ItemAlert
    @item_alerts = ItemAlert.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @item_alerts }
    end
  end

  # GET /item_alerts/1
  # GET /item_alerts/1.json
  def show
    # authorize! :read, @item_alert
    # @item_alert = ItemAlert.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @item_alert }
    end
  end

  def show_table_row
    authorize! :read, @item_alert
    @item_alert = ItemAlert.find(params[:id])

    render layout: false
  end

  # GET /item_alerts/new
  # GET /item_alerts/new.json
  def new
    @item_alert = ItemAlert.new(author: current_user)
    authorize! :create, @item_alert

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @item_alert }
    end
  end

  # GET /item_alerts/1/edit
  def edit
    @item_alert = ItemAlert.find(params[:id])
    authorize! :edit, @item_alert

    respond_to do |format|
      format.html # new.html.erb
      format.js { render layout: false }
    end
  end

  # POST /item_alerts
  # POST /item_alerts.json
  def create
    @item_alert = ItemAlert.new(item_alert_params)
    authorize! :create, ItemAlert

    respond_to do |format|
      if @item_alert.save
        format.html do
          redirect_to @item_alert, notice: 'Item alert was successfully created.'
        end
        format.json do
          render json: @item_alert, status: :created, location: @item_alert
        end
      else
        format.html { render 'new' }
        format.json do
          render json: @item_alert.errors, status: :unprocessable_entity
        end
      end
    end
  end

  # PUT /item_alerts/1
  # PUT /item_alerts/1.json
  def update
    @item_alert = ItemAlert.find(params[:id])
    authorize! :create, @item_alert

    respond_to do |format|
      # if @item_alert.update_attributes(params[:item_alert])
      if @item_alert.update_attributes(item_alert_params)
        format.html do
          redirect_to @item_alert, notice: 'Item alert was successfully updated.'
        end
        format.json { head :no_content }
      else
        format.html { render 'edit' }
        format.json do
          render json: @item_alert.errors, status: :unprocessable_entity
        end
      end
    end
  end

  # DELETE /item_alerts/1
  # DELETE /item_alerts/1.json
  def destroy
    @item_alert = ItemAlert.find(params[:id])
    @item_alert.destroy
    authorize! :delete, @item_alert

    respond_to do |format|
      format.html { redirect_to item_alerts_url }
      format.json { head :no_content }
    end
  end

  private

  def item_alert_params
    # # Unpermitted keys are logged at DEBUG in test and development.
    # # If this bothers you, delete them from params hash here.
    # params.delete(:adv)
    # params.delete(:format)

    params.require(:item_alert).permit(:source, :item_key, :author_id, :alert_type, :start_date, :end_date, :message)

    # params = params[:item_alert]
    # params.permit(:source, :item_key, :author_id, :alert_type, :start_date, :end_date, :message)

    # This is built to return nulled out objects in case of omissions,
    # but if we want to raise exceptions, do this:
    # .require(:author_id)
    # .require(:message)
    # .require(:source)
    # .require(:item_key)
  end
end
