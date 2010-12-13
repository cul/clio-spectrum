class LocationsController < ApplicationController
  layout "blank"

  def show
    @location = Location.match_location_text 

    if @location
      @location_links = {}

    end
  end

end
