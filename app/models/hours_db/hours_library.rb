# class HoursDb::HoursLibrary < ApplicationRecord
#   establish_connection :hours_db_prod
#   self.table_name = 'Libraries'
#   belongs_to :library, class_name: 'Library', primary_key: 'hours_db_code', foreign_key: 'lib_code'
#   has_many :calendars, class_name: 'HoursDb::Calendar', primary_key: 'lib_code', foreign_key: 'cal_library'
# 
#   def find_or_create_for_clio!
#     library || Library.create(to_clio_fmt)
#   end
# 
#   def self.sync_all!(startdate = Date.yesterday, days_to_add = 31)
#     enddate = startdate + days_to_add.days
# 
#     all().each do |hl|
#       # debugging...
#       # next unless /Burk/ =~ hl.lib_name
#       # puts "XXXXXXXXXXXXXXXXXXXXXXXX  #{hl.lib_name}"
#       library = hl.find_or_create_for_clio!
#       # Use "destroy" instead of delete, so that it'll
#       # also clear out associated 'has_options' rows
#       # library.hours.delete_all
#       library.hours.destroy_all
# 
#       # calendars = hl.calendars.find(:all, conditions: ['cal_date BETWEEN ? and ?', startdate, enddate])
#       calendars = hl.calendars.where('cal_date BETWEEN ? and ?', startdate, enddate)
# 
#       calendars.each do |calendar|
#         library.hours.create(calendar.to_clio_fmt)
#       end
#     end
#   end
# 
#   def to_clio_fmt
#     {
#       hours_db_code: lib_code,
#       name: lib_name,
#       comment: (lib_comment.to_s + ' ' + lib_comment_below.to_s).strip,
#       url: lib_url
#     }
#   end
# end
