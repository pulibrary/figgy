# frozen_string_literal: true

class AddPreservationObjectIndexes < ActiveRecord::Migration[5.1]
  def change
    add_index :orm_resources,
      "((metadata->'preserved_object_id'->0->>'id')::UUID)",
      name: "preserved_object_id_idx"
    add_index :orm_resources,
      "((metadata->'resource_id'->0->>'id')::UUID)",
      name: "resource_id_idx"
  end
end
