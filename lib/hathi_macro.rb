module HathiMacro
  # shortcut
  Marc21 = Traject::Macros::Marc21

  OCLC_CLEAN = /^\(OCoLC\)[^0-9A-Za-z]*([0-9A-Za-z]*)[^0-9A-Za-z]*$/

  def hathi_access
    lambda do |record, accumulator, _context|

      local_id = extract_marc('001', first: true)
      
      oclc_numbers = []
      oclc_raw = Marc21.extract_marc_from(record, '035a').flatten.uniq
      oclc_raw.each do |oclc|
        if clean_oclc = oclc.match(OCLC_CLEAN)
          oclc_numbers << clean_oclc[1].gsub(/^[a-z0]/, '')
        end
      end
      
      accumulator << lookup_hathi_access(local_id, oclc_numbers)

    end
  end
  
  def lookup_hathi_access(local_id, oclc_numbers)
    oclc_clause = ''
    oclc_numbers.sort.uniq.each do |oclc|
      oclc_clause += " or oclc = '#{oclc}'"
    end
    
    sql = "select access from hathi_etas where local_id = '#{local_id}'"
    sql += oclc_clause if oclc_clause.present?
    records = ActiveRecord::Base.connection.execute(sql)
    ActiveRecord::Base.clear_active_connections!

    # Search all returned records for highest level of access (allow)
    # If not found, return whatever else we got
    access = nil
    records.each do |record|
      return 'allow' if record['access'] == 'allow'
      access = record['access']
    end
    return access
  end

end



# to_field 'hathi_access' do |record, accumulator|
#   local_id = extract_marc('001', first: true)
#   
#   oclc_numbers = []
#   oclc_raw = Marc21.extract_marc_from(record, '035a').flatten.uniq
#   oclc_raw.each do |oclc|
#     if clean_oclc = oclc.match(OCLC_CLEAN)
#       oclc_numbers << clean_oclc[1]
#     end
#   end
#   
#   accumulator << lookup_hathi_access(local_id, oclc_numbers)
# end
