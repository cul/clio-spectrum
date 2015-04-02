namespace :locations do
  task :load => :environment do
    puts_and_log("Starting rake task to load locations from config/locations_fixture.yml", :info)

    locations = Location.clear_and_load_fixtures!

    puts_and_log(locations.count.to_s + " locations loaded.")
  end
end

