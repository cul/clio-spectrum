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
    # download param may be a year (YYYY) or year/month (YYYY-MM).
    download = log_params[:download]
    if download.present?
      # @rows = Log.where(set: @set).by_year(download).order(:created_at)
      @rows = logs_by_date(download).order(created_at: :asc)
      
      # This set's keys, derived from the JSON logdata of an example row
      @logdata_keys = get_keys_from_logdata(@rows.last)
      # standard keys for any logged requests (ip, user-agent, etc.)
      @request_keys = request_keys
      
      filename = "#{@set} #{download}".parameterize.underscore + '.csv'
      
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

    # # OK, we're going to move forward and display an interactive JS datatable
    # # of a given year/month for a given log set.
    # year, month = @year_month.split(/\-/)
    # 
    # @rows = Log.where(set: @set).by_month(month.to_i, year: year).order(:created_at)

    @rows = logs_by_date(@year_month).order(created_at: :desc)
    
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
      begin
        # If the database save fails, log it, continue the redirect
        Log.create(all_data)
      rescue => ex
        Rails.logger.error "LogsController#bounce error: #{ex.message}"
        Rails.logger.error all_data.inspect
      end
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

  # @rows = log_by_download(download)
  # download param may be a year (YYYY) or year/month (YYYY-MM).
  def logs_by_date(download = nil)
    return ActiveRecord::NullRelation unless download.present?
    return log_by_year(download) if download.match(/^\d\d\d\d$/)
    return log_by_month(download) if download.match(/^\d\d\d\d\-\d\d$/)
    # Any bad data, return null set
    return ActiveRecord::NullRelation
  end
  
  def log_by_year(download)
    # default clause works in MySQL
    where_clause = "year(created_at) = '#{download}'"

    # SQLite needs something special
    if ActiveRecord::Base.connection.adapter_name.match /sqlite/i
      where_clause = "strftime('%Y', created_at) = '#{download}'"
    end

    return Log.where(set: @set).where(where_clause)
  end

  def log_by_month(download)
    year, month = download.split(/-/)
    # default clause works in MySQL
    where_clause = "year(created_at) = '#{year}' AND month(created_at) = '#{month}'"

    # SQLite needs something special
    if ActiveRecord::Base.connection.adapter_name.match /sqlite/i
      where_clause = "strftime('%Y', created_at) = '#{year}' AND strftime('%m', created_at) = '#{month}'"
    end

    return Log.where(set: @set).where(where_clause)
  end
  
  
end

