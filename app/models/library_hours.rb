class LibraryHours < ActiveRecord::Base
  belongs_to :library

  def to_day_of_week
    date.strftime('%A')
  end

  def to_opens_closes
    return 'CLOSED' unless opens && closes

    opens_display = clocktime_to_label(opens)
    closes_display = clocktime_to_label(closes)

    if opens_display == 'Midnight' && closes_display == 'Midnight'
      return '24 Hours'
    end

    return "#{opens_display} - #{closes_display}"
  end

  def self.hours_for_range(library_code, startdate, enddate)
    # hours.find(:all, conditions: ['library_hours.date BETWEEN ? and ?', startdate.to_date, enddate.to_date]).sort { |x, y| x.date <=> y.date }
    self.where(library_code: library_code).where('library_hours.date BETWEEN ? and ?', startdate.to_date, enddate.to_date).sort { |x, y| x.date <=> y.date }
  end

  private

  def clocktime_to_label(clocktime)
    label = clocktime.strftime('%l:%M%p').downcase
    label.gsub!(':00', '')
    return 'Noon' if label == '12pm'
    return 'Midnight' if label == '12am'
    return label
  end

end


