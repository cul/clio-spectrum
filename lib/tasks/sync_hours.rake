namespace :hours do
  task :sync => :environment do
    Rails.logger.info("Starting rake task to sync hours")

    days_forward = ENV["days"] || 31
    HoursDb::HoursLibrary.sync_all!(Date.yesterday, days_forward)

    Rails.logger.info(LibraryHours.count.to_s + " days of hour information synced.")
  end
end

