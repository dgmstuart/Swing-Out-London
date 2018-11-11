# frozen_string_literal: true

class AddPrimaryKeyToEventsSwingCancellations < ActiveRecord::Migration[5.2]
  def change
    add_column :events_swing_cancellations, :id, :primary_key
  end
end
