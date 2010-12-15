class LibraryHours < ActiveRecord::Base
  attr_accessible :opens, :closes, :date, :library_id

  belongs_to :library

  def to_day_of_week
    date.strftime("%a")
  end

  def to_opens_closes
    result = ""
    if opens && closes
      result += (opens.min == 0 ? opens.strftime("%l") : opens.strftime("%l:%M")).strip
      result += opens.strftime("%p") == "PM" ? "p" : "a"
      result += "-" + (closes.min == 0 ? closes.strftime("%l") : closes.strftime("%l:%M")).strip
      result += closes.strftime("%p") == "PM" ? "p" : "a"
    else
      result = "CLOSED"
    end

    return result
  end

end
