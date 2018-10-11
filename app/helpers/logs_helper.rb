module LogsHelper
  
  def get_logdata_field(logdata, field)
    return '' unless logdata.present? && field.present?
    
    begin
      logdata = JSON.parse(logdata)
      return logdata[field]
    rescue => ex
      Rails.logger.error "get_logdata_field(logdata, field) failed: #{ex.message}"
    end
    return ''
  end
  
end
