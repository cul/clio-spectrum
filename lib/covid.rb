#
# module Covid
#
#   # Lookup ETAS status for Columbia records
#   def self.lookup_db_etas_status(id)
#     # skip the DB lookup for non-Voyager ids
#     return nil unless id and id.match(/^\d+$/)
#     table_name = 'hathi_overlap'
#     return Covid.lookup_db_etas_status_in_table(id, table_name)
#   end
#
#   # Lookup ETAS status for Princeton records - stored in a different table
#   def self.lookup_db_etas_status_princeton(id)
#     table_name = 'hathi_overlap_princeton'
#     return Covid.lookup_db_etas_status_in_table(id, table_name)
#   end
#
#   # Field 'access' of the overlap report is either:
#   #   allow - public domain book, no restrictions
#   #   deny  - non-PD, title is under ETAS restrictions
#   def self.lookup_db_etas_status_in_table(id, table_name)
#     begin
#       # sql = "select access from hathi_overlap where local_id = '#{id}'"
#       sql = "select access from #{table_name} where local_id = '#{id}'"
#       records = ActiveRecord::Base.connection.exec_query(sql)
#       ActiveRecord::Base.clear_active_connections!
#       return records.first['access']
#     rescue
#       return nil
#     end
#     return nil
#   end
#
# end
