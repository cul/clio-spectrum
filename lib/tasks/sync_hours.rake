namespace :hours do
  # task :sync => :environment do
  #   Rails.logger.info("Starting rake task to sync hours")
  # 
  #   days_forward = ENV["days"] || 31
  #   HoursDb::HoursLibrary.sync_all!(Date.yesterday, days_forward)
  # 
  #   Rails.logger.info(LibraryHours.count.to_s + " days of hour information synced.")
  # end


  task :libraries => :environment do
    puts "===  List of known libraries  ==="
    Library.all().each do |library|
      printf("%-32s  %s\n", library.hours_db_code, library.name)
    end
  end

  task :update, [:library_code] => :environment do |t, args|
    unless args[:library_code]
      puts "must pass input arg :library_code (e.g.: rake hours:update[butler])" 
      next
    end
    library = Library.where(hours_db_code: args[:library_code]).first
    unless library
      puts "input arg :library must be a valid library code (see: rake hours:libraries)"
      next
    end

    # Setup our API params (one month of data)
    start_date = Date.yesterday.strftime('%F')
    end_date   = (Date.yesterday + 30).strftime('%F')
    # fetch this library's hours from the Hours API
    json = call_hours_api(args[:library_code], start_date, end_date)
    unless json
      puts "ERROR - no json data returned for library code #{args[:library_code]}"
      next
    end

    hours = nil
    begin
      library_data = json['data']
      hours   = library_data[ args[:library_code] ]
    rescue => ex
      puts "ERROR parsing returned json data: #{ex.message}"
      puts hours.inspect
      next
    end

    if hours.blank? || hours.size == 0
      puts "ERROR - no daily hours found for library code #{args[:library_code]}"
      next
    end

    puts "retrieved data for #{hours.size} days for #{args[:library_code]}" 

    # OK, we have what looks like good hours.
    # Now, delete all currently saved hours,
    # insert each day of new hours.

    LibraryHours.where(library_id: library.id).destroy_all
    hours.each do |day|
      daily_hours = {
        library_id: library.id,
        date:       day['date'],
        opens:      "#{day['date']} #{day['open_time']}",
        closes:     "#{day['date']} #{day['close_time']}",
        note:       day['notes']
      }
      LibraryHours.create(daily_hours)
    end


    # sftp = get_sftp()
    # 
    # 
    # @conn = Faraday.new(url: url)
    # raise "Faraday.new(#{url}) failed!" unless @conn
    # @conn.headers['Content-Type'] = 'application/json'
    # 
    # json = 
    # Rake::Task["recap:ingest_file"].reenable
    # Rake::Task["recap:ingest_file"].invoke(filename)


  end


end



# details here:   https://github.com/cul/ldpd-hours
def call_hours_api(library_code, start_date, end_date)
  client = HTTPClient.new
  client.connect_timeout = 5 # default 60
  client.send_timeout    = 5 # default 120
  client.receive_timeout = 5 # default 60
  
  url = 'https://hours.library.columbia.edu/api/v1/locations/'
  url = url + library_code + "?start_date=#{start_date}&end_date=#{end_date}"
  
  begin
    json_holdings = client.get_content(url)
    hours = JSON.parse(json_holdings)
  rescue => ex
    puts "ERROR calling #{url}: #{ex.message}"
    return nil
  end

  # puts "============"
  # puts hours.inspect
  # puts "============"

  hours
end



