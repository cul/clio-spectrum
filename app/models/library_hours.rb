class LibraryHours < ActiveRecord::Base
  belongs_to :library

  def to_day_of_week
    date.strftime('%a')
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

  private

  def clocktime_to_label(clocktime)
    label = clocktime.strftime('%l:%M%p').downcase
    label.gsub!(':00', '')
    return 'Noon' if label == '12pm'
    return 'Midnight' if label == '12am'
    return label
  end

end


