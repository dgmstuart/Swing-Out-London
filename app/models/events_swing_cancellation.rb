# frozen_string_literal: true

class EventsSwingCancellation < ApplicationRecord
  belongs_to :event
  belongs_to :swing_date
  audited associated_with: :event
end
