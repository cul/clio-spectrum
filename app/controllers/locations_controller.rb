class LocationsController < ApplicationController
  layout "blank"

  def show
    @location = Location.match_location_text(params[:id])
    @map_url = @location.find_link_value("Map URL")
    @library = @location.library

    if @library
      @hours = @library.hours_for_range(Date.today, Date.today + 6.days)
    end

    @links = @location.links.reject { |l| l.name == "Map URL" }
  end


end
