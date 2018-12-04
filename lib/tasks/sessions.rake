
# Rails sessions table cleanup, remove recent (but not all) records
#   (for when session_store is set to :active_record_store)
# http://www.softr.li/blog/2012/07/05/setup-automatic-clearing-of-your-rails-sessions

namespace :sessions do
  desc 'Clear expired sessions (more than N days old)'
  task :cleanup, [:days_old] => :environment do |_t, args|
    # args.with_defaults(days_old: 7)
    days_old = (args[:days_old] || 7).to_i
    raise 'input arg :days_old must be > 0' if days_old < 1
    sql = "DELETE FROM sessions WHERE (updated_at < '#{Date.today - days_old.to_i.days}')"
    ActiveRecord::Base.connection.execute(sql)
  end
end
