# frozen_string_literal: true

class DatesStringValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    DatesStringParser.new.parse(value)
  rescue ArgumentError
    record.errors[attribute] << (options[:message] || default_message)
  end

  private

  def default_message
    'is not a valid date string. Use DD/MM/YYYY, separated by commas'
  end
end
