# frozen_string_literal: true

class CreateOrganisers < ActiveRecord::Migration
  def self.up
    create_table :organisers do |t|
      t.string :name
      t.string :website
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :organisers
  end
end
