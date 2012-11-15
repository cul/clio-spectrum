
namespace :databases do
  desc "import database alerts"
  task :import_alerts => :environment do
    author = User.find_by_login("imported_alert")
    author ||= User.create!(:login => "imported_alert", :first_name => "Imported", :last_name => "Alert")

    FileUtils.rm_rf(File.join(Rails.root, "tmp/database_alerts"))
    system("scp -r jws2135@cunix.columbia.edu:/www/data/cu/lweb/eresources/databases/includes tmp/database_alerts")

    ItemAlert.delete_all


    ItemAlert::ALERT_TYPES.each do |alert_type, name|
      puts alert_type
      Dir.glob(File.join(Rails.root, "/tmp/database_alerts/#{alert_type}/*[0-9].html")).each do |filename|
        clio_id = filename.match(/([\d]+)\.html/)[1]
        message = File.read(filename).strip
        unless message.empty?
          ItemAlert.create!(:item_key => clio_id, :author_id => author.id, :source => "catalog", :alert_type => alert_type, :message => message)
        end
      end


    end

    

  end
end
