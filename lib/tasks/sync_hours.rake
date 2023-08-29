namespace :hours do
  # task :sync => :environment do
  #   Rails.logger.info("Starting rake task to sync hours")
  #
  #   days_forward = ENV["days"] || 31
  #   HoursDb::HoursLibrary.sync_all!(Date.yesterday, days_forward)
  #
  #   Rails.logger.info(LibraryHours.count.to_s + " days of hour information synced.")
  # end

  desc 'list known libraries from locations table'
  task libraries: :environment do
    puts '===  List of known libraries  ==='
    # Library.all().each do |library|
    #   printf("%3d %-32s  %s\n", library.id, library.hours_db_code, library.name)
    # end
    Location.all.each do |location|
      printf("%-32s  %s\n", location.library_code, location.name)
    end
  end

  desc 'update hours for all libraries in location table'
  task update_all: :environment do
    # Library.all().each do |library|
    #   printf("Updating %3d %-30s  %s\n", library.id, library.hours_db_code, library.name)
    #   Rake::Task["hours:update"].reenable
    #   Rake::Task["hours:update"].invoke(library.hours_db_code)
    # end
    # Location.select(:location_code).uniq.each do |location|
    library_codes = Location.select(:library_code).uniq.pluck(:library_code).compact.sort
    library_codes.each do |library_code|
      printf("Updating %s\n", library_code)
      Rake::Task['hours:update'].reenable
      Rake::Task['hours:update'].invoke(library_code)
    end
  end

  desc 'update hours for given libary_code (e.g., rake hours:update[bulter])'
  task :update, [:library_code] => :environment do |_t, args|
    unless args[:library_code]
      puts 'must pass input arg :library_code (e.g.: rake hours:update[butler])'
      next
    end
    # library = Library.where(hours_db_code: args[:library_code]).first
    # unless library
    #   puts "input arg :library must be a valid library code (see: rake hours:libraries)"
    #   next
    # end
    location = Location.where(library_code: args[:library_code]).first
    unless location
      puts "input arg (#{args[:library_code]}) must be a valid library code (see: rake hours:libraries)"
      next
    end
    library_code = location.library_code
    puts "Looking up hours for library_code #{library_code}"

    # Setup our API params (one month of data)
    start_date = Date.yesterday.strftime('%F')
    end_date   = (Date.yesterday + 30).strftime('%F')
    # fetch this library's hours from the Hours API
    json = call_hours_api(library_code, start_date, end_date)
    unless json
      puts "ERROR - no json data returned for library code #{library_code}"
      next
    end

    hours = nil
    begin
      library_data = json['data']
      hours = library_data[library_code]
    rescue => ex
      puts "ERROR parsing returned json data: #{ex.message}"
      puts hours.inspect
      next
    end

    if hours.blank? || hours.size.zero?
      puts "ERROR - no daily hours found for library code #{library_code}"
      next
    end

    puts "retrieved data for #{hours.size} days for #{library_code}"

    # OK, we have what looks like good hours.
    # Now, delete all currently saved hours,
    # insert each day of new hours.

    LibraryHours.where(library_code: library_code).destroy_all
    hours.each do |day|
      # Assume closed, unless we have open/close times
      opens = closes = nil
      opens  = "#{day['date']} #{day['open_time']}"  if day['open_time']
      closes = "#{day['date']} #{day['close_time']}" if day['close_time']
      # But even so, the 'closed' field overrides any given hours
      opens = closes = nil if day['closed']

      daily_hours = {
        library_id:   0, # no longer used
        library_code: library_code,
        date:         day['date'],
        opens:        opens,
        closes:       closes,
        note:         day['note']
      }
      LibraryHours.create(daily_hours)
    end

    # @conn = Faraday.new(url: url)
    # raise "Faraday.new(#{url}) failed!" unless @conn
    # @conn.headers['Content-Type'] = 'application/json'
  end
end

# details here:   https://github.com/cul/ldpd-hours
def call_hours_api(library_code, start_date, end_date)
  client = HTTPClient.new
  client.ssl_config.set_default_paths
  client.connect_timeout = 5 # default 60
  client.send_timeout    = 5 # default 120
  client.receive_timeout = 5 # default 60

  url = 'https://hours.library.columbia.edu/api/v1/locations/'
  url = url + library_code + "?start_date=#{start_date}&end_date=#{end_date}"

  begin
    message = client.get(url)
    if message.status == 404
      puts "Hours for library [#{library_code}] not found (404 from API)"
      return
    end
    # json_holdings = client.get_content(url)
    json_holdings = message.body
    hours = JSON.parse(json_holdings)
  rescue => ex
    puts "ERROR calling #{url}: #{ex.message}"
    return nil
  end

  # puts "============"
  # puts hours.to_yaml
  # puts "============"

  hours
end
