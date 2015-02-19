class Location < ActiveRecord::Base
  CATEGORIES = %w(library info)
  attr_accessible :name, :found_in, :library_id, :category, :library_code
  belongs_to :library

  has_options association_name: :links

  # def is_open?(check_at = Datetime.now)
  #   library ? library.is_open?(check_at) : false
  # end

  def self.match_location_text(location = nil)
    # move this out to the caller
    # # location comes from URL, and so will be escaped (e.g., spaces will be '+')
    # unescaped_location = CGI.unescape(location)
    # # logger.debug("match_location_text: looking for " + location)

    if connection.adapter_name.downcase.include?('mysql')
      matches = find(:all, conditions: ["? LIKE CONCAT(locations.name, '%')", location], include: :library)
    else
      matches = find(:all, conditions: ["? LIKE locations.name || '%'", location], include: :library)
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
    Location.delete_all
    fixture = YAML.load_file('config/locations_fixture.yml')

    fixture.each do |location_hash|
      library = Library.find_by_hours_db_code(location_hash[:library_code]) if location_hash[:library_code]

      location = Location.create!(
        name: location_hash[:location],
        found_in: location_hash[:found_in],
        category: location_hash[:category],
        library_id: (library.nil? ? nil : library.id),
        library_code: location_hash[:library_code]
      )

      if location

        location_hash[:links].each_pair do |name, url|
          location.links.create(name: name, value: url)
        end
      end
    end
  end
end
