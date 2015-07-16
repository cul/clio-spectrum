class LibraryHours < ActiveRecord::Base
  # attr_accessible :opens, :closes, :date, :library_id

  belongs_to :library

  def to_day_of_week
    date.strftime('%a')
  end

  def to_opens_closes
    result = ''
    if opens && closes

      if opens.strftime('%l:%M%p') == '12:00PM'
        opens_display = 'Noon'
      elsif opens.strftime('%l:%M%p') == '12:00AM'
        opens_display = 'Midnight'
      else
        opens_display = (opens.min == 0 ? opens.strftime('%l') : opens.strftime('%l:%M')).strip
        opens_display += opens.strftime('%p') == 'PM' ? 'pm' : 'am'
      end

      if closes.strftime('%l:%M%p') == '12:00PM'
        closes_display = 'Noon'
      elsif closes.strftime('%l:%M%p') == '12:00AM'
        closes_display = 'Midnight'
      else
        closes_display = (closes.min == 0 ? closes.strftime('%l') : closes.strftime('%l:%M')).strip
        closes_display += closes.strftime('%p') == 'PM' ? 'pm' : 'am'
      end

      if opens_display == 'Midnight' && closes_display == 'Midnight'
        result = '24 Hours'
      else
        result = "#{opens_display}-#{closes_display}"
      end

    else
      result = 'CLOSED'
    end

    result
  end
end
