# frozen_string_literal: true
class CreateProcessedEvents < ActiveRecord::Migration[5.1]
  def change
    create_table :processed_events do |t|
      t.integer :event_id

      t.timestamps null: false
    end
  end
end
