namespace :hours do
  task :sync => :environment do
    RAILS_DEFAULT_LOGGER.info "Starting rake task to sync hours"
    days_forward = ENV["days"] || 31
    HoursDb::HoursLibrary.sync_all!(Date.yesterday, days_forward)
    puts "#{LibraryHours.count} days of hour information synced."
    RAILS_DEFAULT_LOGGER.info "#{LibraryHours.count} days of hour information available."
  end
end
