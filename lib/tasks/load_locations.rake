namespace :locations do
    desc("Starting rake task to load locations from config/locations_fixture.yml")

    task :load => :environment do
      locations = Location.clear_and_load_fixtures!
      Rails.logger.info(locations.count.to_s + " locations loaded.")
    end

  end
