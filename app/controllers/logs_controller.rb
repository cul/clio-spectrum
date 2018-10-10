class LogsController < ApplicationController

  require 'csv'
  
  layout 'no_sidebar'

# /logs/set=XXX
#  - earliest/latest info
#  - for each year, record-count, download-link
#      - for each month, record-count, download-link
# ... and datatable, at what level?  Day or Month or Year?
# ... determined by record-count at that level?  (if < N, link)

  def index
    @set = log_params[:set]
    
    # If no set of logs was specified,
    # ask for which one.
    if @set.blank?
      @set_counts = Log.group('set').distinct.count
      return render action: 'set_list'
    end

    # Have they asked to download a year of logs for a given log set?
    @download = log_params[:download]
    if @download.present?
      @rows = Log.where(set: @set).by_year(@download).order(:created_at)
      
      # This set's keys, derived from the JSON logdata of an example row
      @logdata_keys = get_keys_from_logdata(@rows.last)
      # standard keys for any logged requests (ip, user-agent, etc.)
      @request_keys = request_keys
      
      filename = "#{@set} #{@download}".parameterize.underscore + '.csv'
      
      response.headers['Content-Type'] = 'text/csv'
      response.headers['Content-Disposition'] = "attachment; filename=#{filename}"
      return render template: 'logs/index.csv.erb'
    end
    
    @year_month = log_params[:year_month]

    # If they haven't told us which year/month to display,
    # ask them.
    if @year_month.blank?
      @year_counts = get_year_counts
      @month_counts = get_month_counts
      return render action: 'month_list'
    end

    # OK, we're going to move forward and display an interactive JS datatable
    # of a given year/month for a given log set.
    year, month = @year_month.split(/\-/)
    
    @rows = Log.where(set: @set).by_month(month.to_i, year: year).order(:created_at)
    
    # This set's keys, derived from the JSON logdata of an example row
    @logdata_keys = get_keys_from_logdata(@rows.last)

    # standard keys for any logged requests (ip, user-agent, etc.)
    @request_keys = request_keys
    
  end
  
  # Bounce the user to a destination URL,
  # while logging the event
  def bounce
    url = log_params[:url]
    # can't redirect, go to root
    if url.blank?
      Rails.logger.error "LogsController#bounce() called w/out 'url' param"
      return redirect_to root_path, flash: { error: 'No destination URL given' }
    end

    # can't log - redirect w/log record
    set = log_params[:set]
    if set.present?
      # logdata is a serial
      logdata = log_params[:logdata] || ''
      all_data = request_data.merge(set: set, logdata: logdata)
      Log.create(all_data)
    else
      Rails.logger.error "LogsController#bounce(#{url}) called w/out 'set' param"
    end
    
    return redirect_to url
  end

  # Display a list of available log sets
  # ('Best Bets', etc.)
  def sets
    
  end


  private

  def log_params
    params.permit(:set, :logdata, :url, :year_month, :download, :format)
  end

  # Return a hash with a set of attributes
  # of the current request, to be added to
  # a given log entry.
  # What do we want to know?
  # Referrer, Timestamp, IP, 
  def request_data
    data = Hash.new
    data[:user_agent] = request.user_agent
    data[:referrer]   = request.referrer
    data[:remote_ip]  = request.remote_ip
    return data
  end
  
  # return array of keys of the basic request fields
  def request_keys
    return [:created_at, :user_agent, :referrer, :remote_ip]
  end
  
  # Figure out appropriate keys for this log set by looking
  # at the JSON logdata of the first retrieved row
  def get_keys_from_logdata(row)
    return [] if row.blank?
    begin
      logdata = JSON.parse( row['logdata'] )
      return logdata.keys
    rescue
      Rails.logger.warn "JSON.parse() failed for row [#{row.inspect}]"
    end
    return []
  end
  
  def get_year_counts
    # default clause works in MySQL
    where_clause = 'year(created_at)'

    # SQLite needs something special
    if ActiveRecord::Base.connection.adapter_name.match /sqlite/i
      where_clause = 'strftime("%Y", created_at)'
    end

    return Log.where(set: @set).order(:created_at).group(where_clause).count
  end
  
  def get_month_counts
    # default clause works in MySQL
    where_clause = "concat( year(created_at), '-', month(created_at) )"

    # SQLite needs something special
    if ActiveRecord::Base.connection.adapter_name.match /sqlite/i
      where_clause = 'strftime("%Y-%m", created_at)'
    end

    return Log.where(set: @set).order(:created_at).group(where_clause).count
  end
    
  
  
end

