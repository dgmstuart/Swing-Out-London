# frozen_string_literal: true

class DatesStringParser
  def parse(dates_string)
    String(dates_string).split(',').map(&:to_date).uniq
  end
end
