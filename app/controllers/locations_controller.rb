class LocationsController < ApplicationController
  layout 'blank'

  def show
    @location = Location.match_location_text(params[:id])
    if @location
      @map_url = @location.find_link_value('Map URL')
      @library = @location.library

      if @library
        range_start = Date.today
        @hours = @library.hours_for_range(range_start, range_start + 6.days)
      end

      @links = @location.links.reject { |location| location.name == 'Map URL' }

      @location_notes = Location.get_app_config_location_notes(@location['name']).html_safe
    end
  end
end
