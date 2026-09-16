require 'rest-client'
class LocationsController < ApplicationController
  layout 'location'

  DayInfo = Struct.new(:to_day_of_week, :to_opens_closes, :note)

  def show
    # raw_location comes from the Voyager response.  It might be something like:
    #     Avery Classics - By appt. (Non-Circulating)
    # @location is retrieved from loaded fixtures.  location['name'] might be:
    #     Avery Classics

    # raw_location comes from URL, and so will be escaped (e.g., spaces will be '+')
    raw_location = CGI.unescape(params[:id])

    # @location = Location.match_location_text(params[:id])
    @location = Location.match_location_text(raw_location)
    if @location
      @markers = build_markers
      @hours = nil

      if @location.library_code
        range_start = Date.today
        # fcd1, 90/16/26: To backout of NEXT-2093, uncomment next line, and comment out the line after
        # @hours = LibraryHours.hours_for_range(@location.library_code, range_start, range_start + 6.days)
        @hours = get_hours(@location.library_code)
      end

      @display_title = @library ? @library.name : @location.name
      @links = @location.links.reject { |link| link.name == 'Map URL' }

      # @location_notes = Location.get_app_config_location_notes(@location['name']).html_safe
      @location_notes = Location.get_app_config_location_notes(raw_location)
      @location_notes.html_safe if @location_notes
    end
  end

  def library_api_path
    if APP_CONFIG.key?('library_api_path') && APP_CONFIG['library_api_path']
      APP_CONFIG['library_api_path']
    else
      # 'https://api.library.columbia.edu/query.json'
      'https://api.library.columbia.edu/locations/v2/query.json'
    end
  end

  def library_api_info
    # TODO: after API upgrade
    # change this to library_api_return["locations"]
    @library_api_return.is_a?(Hash) ? @library_api_return['locations'] : @library_api_return
  end

  def default_image_url
    # TODO: after API upgrade
    # change this to library_api_return["defaultImageURL"]
    @library_api_return.is_a?(Hash) ? @library_api_return['defaultImageURL'] : 'https://library.columbia.edu/content/dam/locations/location.png'
  end

  def build_markers
    @library_api_return = []
    begin
      # repeatedly re-fetch the full ALL-Location JSON...
      @library_api_return = JSON.parse(
        RestClient.get(library_api_path)
      )
    rescue => ex
      Rails.logger.error "LocationsController error fetching location data from #{library_api_path}: #{ex.message}"
    end

    # puts "@library_api_return:" + @library_api_return.to_s  # DEBUG

    # And get all location records...
    @locations = Location.all
    api_loc = library_api_info.select { |m| m['locationID'] == @location['location_code'] }
    api_display_name = api_loc.present? ? api_loc.first['displayName'] : nil
    @display_map = @location.location_code && api_display_name

    if @display_map
      locations_in_both = library_api_info.map { |m| m['locationID'] } & Location.all.map { |m| m['location_code'] }
      locations_to_display = library_api_info.select { |m| locations_in_both.include? m['locationID'] }
      markers = Gmaps4rails.build_markers(locations_to_display) do |location, marker|
        marker.lat location['latitude']
        marker.lng location['longitude']
        marker.title location['displayName'] ? location['displayName'] : location['officialName']
        marker.infowindow render_to_string(partial: 'locations/infowindow',
                                           locals: { library_info: location, default_image_path: default_image_url })
        marker.json(location_code: location['locationID'])
      end
      @current_marker_index = markers.find_index { |mark| mark[:location_code] == @location.location_code }

      ### DEBUGGING
      # puts ">>>>>>>>>>>>>>>>>  markers.class=" + markers.class.to_s
      # puts ">>>>>>>>>>>>>>>>>  markers.length=" + markers.length.to_s
      # markers.each { |marker| puts ">>>>>>>> ---- " + marker[:location_code]}

      markers.to_json
    end
  end

  # fcd1, 09/16/26: methods get_hours, fetch_hours, prep_days_info were added for NEXT-2093.
  # If backing out of NEXT-2093, leaving these methods in the code is fine, just won't be called.
  def get_hours(library_code)
    date_today = DateTime.now
    hours_info = fetch_hours(library_code,
                            date_today.strftime('%Y-%m-%d'),
                            (date_today + 6).strftime('%Y-%m-%d'))
    prep_days_info(hours_info)
  end

  # This method encapsulates the call to the hours API
  def fetch_hours(library_code, start_date, end_date)
    Rails.logger.warn "Calling Hours API"
    hours_api_locations_url = APP_CONFIG['hours_api_locations_url']
    uri = URI("#{hours_api_locations_url}#{library_code}")
    uri.query = URI.encode_www_form(start_date: start_date, end_date: end_date)

    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      parsed_response = JSON.parse(response.body)
      hours_info = parsed_response["data"][library_code]
    else
      hours_info = nil
    end
    hours_info
  end

  # This method is used to format for display in CLIO the hours info returned by the hours API
  def prep_days_info(hours_info)
    return nil unless hours_info
    days_info = []
    hours_info.each do |day|
      prepped_formatted_date =
        day["formatted_date"].delete_prefix("0").gsub(/-0*/, ' - ').gsub(/(AM|PM)/, ' \1')
      day_info = DayInfo.new(DateTime.strptime(day["date"], '%Y-%m-%d').strftime('%A'),
                             prepped_formatted_date,
                             day["note"])
      days_info << day_info
    end
    days_info
  end

  private

  def location_params
    parms.permit(:name, :found_in, :library_id, :category, :location_code)
  end
end
