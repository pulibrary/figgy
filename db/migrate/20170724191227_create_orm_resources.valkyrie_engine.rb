# This migration comes from valkyrie_engine (originally 20161007101725)
# frozen_string_literal: true

class CreateOrmResources < ActiveRecord::Migration[5.0]
  def change
    create_table :orm_resources, id: :uuid do |t|
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :orm_resources, :metadata, using: :gin
  end
end
