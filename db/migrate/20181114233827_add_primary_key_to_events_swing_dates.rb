# frozen_string_literal: true

class AddPrimaryKeyToEventsSwingDates < ActiveRecord::Migration[5.2]
  def change
    add_column :events_swing_dates, :id, :primary_key
  end
end
