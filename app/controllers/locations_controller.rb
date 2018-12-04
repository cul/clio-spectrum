require 'rest-client'
class LocationsController < ApplicationController
  layout 'location'

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
        @hours = LibraryHours.hours_for_range(@location.library_code, range_start, range_start + 6.days)
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
      'https://api.library.columbia.edu/query.json'
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
        RestClient.get(library_api_path,
                       params: { qt: 'location', locationID: 'alllocations' })
      )
    rescue => ex
      Rails.logger.error "LocationsController error fetching location data from #{library_api_path}: #{ex.message}"
    end
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
      markers.to_json
    end
  end

  private

  def location_params
    parms.permit(:name, :found_in, :library_id, :category, :location_code)
  end
end
