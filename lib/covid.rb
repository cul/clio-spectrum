
module Covid

  def self.lookup_db_etas_status(id)
    begin
      sql = "select access from hathi_overlap where local_id = '#{id}'"
      records = ActiveRecord::Base.connection.exec_query(sql)
      ActiveRecord::Base.clear_active_connections!
      return records.first['access']
    rescue
      return nil
    end
    return nil
  end

end
