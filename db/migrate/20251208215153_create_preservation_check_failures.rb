# frozen_string_literal: true
class CreatePreservationCheckFailures < ActiveRecord::Migration[7.2]
  def change
    create_table :preservation_check_failures do |t|
      t.belongs_to :preservation_audit
      t.string :resource_id

      t.timestamps
    end
  end
end
