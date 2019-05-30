# frozen_string_literal: true

require 'rails_helper'

class Validatable
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :string

  validates :string, dates_string: true
end

RSpec.describe DatesStringValidator do
  context 'when the date string could be parsed' do
    it 'is valid' do
      valid_string = double
      parser = instance_double(DatesStringParser)
      allow(DatesStringParser).to receive(:new).and_return(parser)
      allow(parser).to receive(:parse).with(valid_string).and_return double

      instance = Validatable.new(string: valid_string)

      expect(instance).to be_valid
    end

    it 'is invalid' do
      invalid_string = double
      parser = instance_double(DatesStringParser)
      allow(DatesStringParser).to receive(:new).and_return(parser)
      allow(parser).to receive(:parse).with(invalid_string).and_raise(ArgumentError, 'invalid date')

      instance = Validatable.new(string: invalid_string)

      expect(instance).to be_invalid
    end
  end
end
