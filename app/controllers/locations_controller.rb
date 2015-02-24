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
      @map_url = @location.find_link_value('Map URL')
      @library = @location.library
      @library_api_info = JSON.parse(RestClient.get "http://api.library.columbia.edu/query.json", {params: {qt: 'location', locationID: 'butler'}})

      @markers = build_markers

      if @library
        range_start = Date.today
        @hours = @library.hours_for_range(range_start, range_start + 6.days)
        # debugging...
        # range_start = Date.today - 10
        # @hours = @library.hours_for_range(range_start, range_start + 20.days)
      end

      @links = @location.links.reject { |location| location.name == 'Map URL' }

      # @location_notes = Location.get_app_config_location_notes(@location['name']).html_safe
      @location_notes = Location.get_app_config_location_notes(raw_location)
      @location_notes.html_safe if @location_notes
    end
  end

  def build_markers
    #TODO we want to map these to clio locations and display clio name in infowindow and top of page
    @library_api_info = JSON.parse(RestClient.get "http://api.library.columbia.edu/query.json", {params: {qt: 'location', locationID: 'alllocations'}})
    markers = Gmaps4rails.build_markers(@library_api_info.select{|m| m['showOnMap']}) do |location, marker|
      marker.lat location['latitude']
      marker.lng location['longitude']
      marker.title @location.library['name']
      marker.infowindow render_to_string(partial: 'locations/infowindow', locals: {library_info: location})
      marker.json({ :library_code => location['locationID'] })
    end
    @current_marker_index = markers.find_index{|mark| mark[:library_code] == @location.library_code}
    markers.to_json
  end
end
