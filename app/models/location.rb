class Location < ApplicationRecord
  # CATEGORIES = %w(library info)

  # Rails 4 - remove this
  # attr_accessible :name, :found_in, :library_id, :category, :location_code

  # belongs_to :library

  has_options association_name: :links

  # def is_open?(check_at = Datetime.now)
  #   library ? library.is_open?(check_at) : false
  # end

  # Given a string location, e.g., "Butler Mezzanine",
  # query the Location table for a partial match (e.g., "Butler%"),
  # return the Location object
  def self.match_location_text(location_text = nil)
    return unless location_text && location_text.length > 2

    location_text = location_text.strip

    # move this out to the caller
    # # location comes from URL, and so will be escaped (e.g., spaces will be '+')
    # unescaped_location = CGI.unescape(location)
    # # logger.debug("match_location_text: looking for " + location)

    if connection.adapter_name.downcase.include?('mysql')
      # matches = find(:all, conditions: ["? LIKE CONCAT(locations.name, '%')", location], include: :library)
      # matches = where("? LIKE CONCAT(locations.name, '%')", location_text).joins('LEFT OUTER JOIN libraries ON libraries.id = locations.library_id')
      matches = where("? LIKE CONCAT(locations.name, '%')", location_text)
    else
      # matches = find(:all, conditions: ["? LIKE locations.name || '%'", location], include: :library)
      # matches = where("? LIKE locations.name || '%'", location_text).joins('LEFT OUTER JOIN libraries ON libraries.id = locations.library_id')
      matches = where("? LIKE locations.name || '%'", location_text)
    end

    max_length = matches.map { |m| m.name.length }.max
    matches.find { |m| m.name.length == max_length }
  end


  # Location Note, used for a special add-on text/link message
  # location_note = Location.get_location_note(entry['location_name'])
  def self.get_app_config_location_notes(location = nil)
    return nil unless location

    location_notes = ''
    app_config_location_notes = APP_CONFIG['location_notes'] || {}
    app_config_location_notes.keys.each { |location_note_key|
      if location.starts_with? location_note_key
        location_notes << app_config_location_notes[location_note_key].html_safe
      end
    }

    return location_notes if location_notes.length > 0
    return nil
  end

  def self.clear_and_load_fixtures!
    # Use "destroy" instead of delete, so that it'll
    # also clear out associated 'has_options' rows
    # Location.delete_all
    Location.destroy_all
    fixture = YAML.load_file('config/locations_fixture.yml')

    fixture.each do |location_hash|
      # puts "vvv"
      # puts location_hash.inspect
      # puts "^^^"
      # library = Library.find_by_hours_db_code(location_hash[:library_code]) if location_hash[:library_code]

      location = Location.create!(
        name:          location_hash[:location],
        found_in:      location_hash[:found_in],
        category:      location_hash[:category],
        location_code: location_hash[:location_code],
        library_code: location_hash[:library_code],
        # library_id: (library.nil? ? nil : library.id)
      )

      # Add links to this location, if they exist
      if location && location_hash[:links]
        location_hash[:links].each_pair do |name, url|
          location.links.create(name: name, value: url)
        end
      end

    end
  end
end
