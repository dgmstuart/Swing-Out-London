# frozen_string_literal: true

require 'rails_helper'
require 'support/shoulda_matchers'

RSpec.describe Venue do
  describe 'Associations' do
    it { is_expected.to have_many(:events).dependent(:restrict_with_exception) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:address) }
    it { is_expected.to validate_presence_of(:area) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'can_delete?' do
    it 'is true if there are no associated events' do
      venue = FactoryBot.build(:venue)

      expect(venue.can_delete?).to eq true
    end

    it 'is false if there are associated events' do
      venue = FactoryBot.create(:venue)
      FactoryBot.create(:event, venue: venue)

      expect(venue.can_delete?).to eq false
    end
  end
end
