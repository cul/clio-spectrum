### LIBSYS-3996 - End ETAS
# module HathiMacro
#   # shortcut
#   Marc21 = Traject::Macros::Marc21
#
#   OCLC_CLEAN = /^\(OCoLC\)[^0-9A-Za-z]*([0-9A-Za-z]*)[^0-9A-Za-z]*$/
#
#   def hathi_access
#     lambda do |record, accumulator, _context|
#
#       local_id = Marc21.extract_marc_from(record, '001', first: true).first
#
#       # We're directly loading Hathi public domain records.
#       # These don't need a Hathi Access indicator.
#       return if local_id.starts_with? 'ht'
#
#       oclc_numbers = []
#       oclc_raw = Marc21.extract_marc_from(record, '035a').flatten.uniq
#       oclc_raw.each do |oclc|
#         if clean_oclc = oclc.match(OCLC_CLEAN)
#           oclc_numbers << clean_oclc[1].gsub(/^[a-z0]+/, '')
#         end
#       end
#
#       # - lookup access level in database table
#       hathi_access = lookup_hathi_access(local_id, oclc_numbers)
#       # - add to Solr record if present - skip nils/empty-strings
#       accumulator << hathi_access if hathi_access.present?
#
#     end
#   end
#
#   def lookup_hathi_access(local_id, oclc_numbers)
#     oclc_clause = ''
#     oclc_numbers.sort.uniq.each do |oclc|
#       oclc_clause += " or oclc = '#{oclc}'"
#     end
#
#     # Turn off DEBUG-level logging for SQL
#     ActiveRecord::Base.logger.level = Logger::INFO
#
#     # sql = "select access from hathi_etas where local_id = '#{local_id}'"
#     sql = "select access from hathi_overlap where local_id = '#{local_id}'"
#     sql += oclc_clause if oclc_clause.present?
#     records = ActiveRecord::Base.connection.exec_query(sql)
#     ActiveRecord::Base.clear_active_connections!
#
#     # Search all returned records for highest level of access (allow)
#     # If not found, return whatever else we got
#     access = nil
#     records.each do |record|
#       return 'allow' if record['access'] == 'allow'
#       access = record['access']
#     end
#     return access
#   end
#
# end
#
#
