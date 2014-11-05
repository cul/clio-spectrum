class HoursDb::Calendar < ActiveRecord::Base
  establish_connection 'hours_db_prod'
  self.table_name = 'Calendar'

  belongs_to :library, class_name: 'HoursDb::HoursLibrary', primary_key: 'lib_code', foreign_key: 'cal_library'

  def open
    return nil if cal_open.nil?

    # This says, move X seconds forward from midnight.  It breaks during
    # daylight-savings-time transitions when an hour is skipped or repeated.
    # cal_open.nil? ? nil : cal_date + cal_open.hour.hours + cal_open.min.minutes

    # This creates a string representation of the date-time, then parses it.
    # Seems to get around DST issues and be ok otherwise.
    return Time.zone.parse(cal_date.to_s(:db) + " " + cal_open.to_s(:time))
  end

  def close
    return nil if cal_close.nil?

    # Special treatment when open 24-hours...
    return (cal_date + 24.hours) if (cal_close.hour.hours == 0)

    # Otherwise...
    return Time.zone.parse(cal_date.to_s(:db) + " " + cal_close.to_s(:time))

    # cal_close.nil? ? nil : cal_date + (cal_close.hour.hours == 0 ? 24.hours : (cal_close.hour.hours + cal_close.min.minutes))
  end

  def to_new_books_fmt
    {
      library_id: library.library.id,
      date: cal_date,
      opens: open,
      closes: close,
      note: day_notes
    }
  end
end
