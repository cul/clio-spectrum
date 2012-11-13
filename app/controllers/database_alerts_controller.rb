class DatabaseAlertsController < ApplicationController
  # GET /database_alerts
  # GET /database_alerts.json
  def index
    @database_alerts = DatabaseAlert.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @database_alerts }
    end
  end

  # GET /database_alerts/1
  # GET /database_alerts/1.json
  def show
    @database_alert = DatabaseAlert.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @database_alert }
    end
  end

  # GET /database_alerts/new
  # GET /database_alerts/new.json
  def new
    @database_alert = DatabaseAlert.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @database_alert }
    end
  end

  # GET /database_alerts/1/edit
  def edit
    @database_alert = DatabaseAlert.find(params[:id])
  end

  # POST /database_alerts
  # POST /database_alerts.json
  def create
    @database_alert = DatabaseAlert.new(params[:database_alert])

    respond_to do |format|
      if @database_alert.save
        format.html { redirect_to @database_alert, notice: 'Database alert was successfully created.' }
        format.json { render json: @database_alert, status: :created, location: @database_alert }
      else
        format.html { render action: "new" }
        format.json { render json: @database_alert.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /database_alerts/1
  # PUT /database_alerts/1.json
  def update
    @database_alert = DatabaseAlert.find(params[:id])

    respond_to do |format|
      if @database_alert.update_attributes(params[:database_alert])
        format.html { redirect_to @database_alert, notice: 'Database alert was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @database_alert.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /database_alerts/1
  # DELETE /database_alerts/1.json
  def destroy
    @database_alert = DatabaseAlert.find(params[:id])
    @database_alert.destroy

    respond_to do |format|
      format.html { redirect_to database_alerts_url }
      format.json { head :no_content }
    end
  end
end
