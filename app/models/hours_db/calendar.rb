class HoursDb::Calendar < ActiveRecord::Base
  set_table_name "Calendar"
  establish_connection "hours_db_prod"

  belongs_to :library, :class_name => "HoursDb::HoursLibrary", :primary_key => "lib_code", :foreign_key => "cal_library"


  def open
    cal_open.nil? ? nil : cal_date + cal_open.hour.hours
  end


  def close
    cal_close.nil? ? nil : cal_date + cal_close.hour.hours
  end

  def to_new_books_fmt
    {
      :library_id => library.library.id,
      :date => cal_date,
      :opens => open,
      :closes => close,
      :note => day_notes
    }


  end
end
