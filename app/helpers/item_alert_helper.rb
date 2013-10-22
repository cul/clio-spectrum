module ItemAlertHelper

  # Not so clever - using Bootstrap alert-type labels to mean 'future', 'past', etc. 
  def alert_status(alert)
    right_now = DateTime.now
    start_date = alert.start_date
    end_date = alert.end_date

    # not in-effect - future
    if start_date && start_date > right_now
      "info"
    else
      # currently in-effect
      if end_date.nil? || end_date > (right_now + 3.days)
        "success"
      # currently in-effect, but due to expire soon
      elsif end_date > right_now
        "warning"
      else
        # not in effect - past
        "error"
      end
    end
  end

  def render_alert_duration(alert)
    right_now = DateTime.now()
    raw_start_date = alert.start_date
    pretty_start_date = raw_start_date.to_formatted_s(:short)
    raw_end_date = alert.end_date
    pretty_end_date = raw_end_date.to_formatted_s(:short)

    if raw_start_date
      if raw_end_date
        "#{pretty_start_date} - #{pretty_end_date}"
      else
        if raw_sart_date > right_now
          "Starts #{pretty_start_date}"
        else
          "Started #{pretty_start_date}"
        end
      end

    else    # no start-date given...
      if raw_end_date
        if raw_end_date > right_now
          "Ends #{pretty_end_date}"
        else
          "Ended #{pretty_end_date}"
        end
      else
        "Forever"
      end
    end

  end

end
