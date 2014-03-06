
# Rails sessions table cleanup, remove recent (but not all) records
#   (for when session_store is set to :active_record_store)
# http://www.softr.li/blog/2012/07/05/setup-automatic-clearing-of-your-rails-sessions

namespace :sessions do
  desc "Clear expired sessions (more than 1 weeks old)"
  task :cleanup => :environment do
    sql = "DELETE FROM sessions WHERE (updated_at < '#{Date.today - 1.weeks}')"
    ActiveRecord::Base.connection.execute(sql)
  end
end
