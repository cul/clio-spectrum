namespace :hours do
  task :sync => :environment do
    puts_and_log("Starting rake task to sync hours", :info)
    
    days_forward = ENV["days"] || 31
    HoursDb::HoursLibrary.sync_all!(Date.yesterday, days_forward)
    
    puts_and_log(LibraryHours.count.to_s + " days of hour information synced.")
  end
end

