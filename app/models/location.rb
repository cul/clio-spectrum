class Location < ActiveRecord::Base
  CATEGORIES = %w{library info}
  attr_accessible :name, :found_in, :library_id, :category
  belongs_to :library

  has_options :association_name => :links

  def is_open?(check_at = Datetime.now)
    library ? library.is_open?(check_at) : false
  end

  def self.match_location_text(location = nil)
    # location comes from URL, and so will be escaped (e.g., spaces will be '+')
    unescaped_location = CGI::unescape(location)
    # logger.debug("match_location_text: looking for " + location)
    if self.connection.adapter_name.downcase.include?("mysql")

      matches = self.find(:all, :conditions => ["? LIKE CONCAT(locations.name, '%')", unescaped_location], :include => :library)
    else
      matches = self.find(:all, :conditions => ["? LIKE locations.name || '%'", unescaped_location], :include => :library)

    end

    max_length = matches.collect { |m| m.name.length }.max
    matches.detect { |m| m.name.length == max_length }

  end

  def self.clear_and_load_fixtures!
    Location.delete_all
    fixture = YAML::load_file("config/locations_fixture.yml")

    fixture.each do |location_hash|
      library = Library.find_by_hours_db_code(location_hash[:library_code]) if location_hash[:library_code]

      location = Location.create(
        :name => location_hash[:location],
        :found_in => location_hash[:found_in],
        :category => location_hash[:category],
        :library_id => (library.nil? ? nil : library.id)
      )

      if location

        location_hash[:links].each_pair do |name, url|
          location.links.create(:name => name, :value => url)
        end
      end
    end

  end
end
