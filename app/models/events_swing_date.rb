# frozen_string_literal: true

class EventsSwingDate < ApplicationRecord
  belongs_to :event
  belongs_to :swing_date
  audited associated_with: :event
end
