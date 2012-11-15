module ItemAlertHelper
  def alert_status(alert)
    if alert.start_date && alert.start_date > DateTime.now
      "info"
    else
      if alert.end_date.nil? || alert.end_date > (DateTime.now + 3.days)
        "success"
      elsif alert.end_date > DateTime.now
        "warning"
      else
        "error"
      end
    end
  end

  def render_alert_duration(alert)
    if alert.start_date.nil? 
      if alert.end_date.nil?
        "Always Visible"
      else
        if alert.end_date > DateTime.now()
          "Ends #{alert.end_date.to_formatted_s(:short)}"
        else
          "Ended #{alert.end_date.to_formatted_s(:short)}"
        end
      end
    else
      if alert.end_date.nil?
        if alert.start_date > DateTime.now()
          "Starts #{alert.start_date.to_formatted_s(:short)}"
        else
          "Started #{alert.start_date.to_formatted_s(:short)}"
        end
      else
        "#{alert.start_date.to_formatted_s(:short)} - #{alert.end_date.to_formatted_s(:short)}"
      end
    end


  end

end
