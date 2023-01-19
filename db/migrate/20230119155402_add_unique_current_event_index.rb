# frozen_string_literal: true
class AddUniqueCurrentEventIndex < ActiveRecord::Migration[6.1]
  def change
    add_index :orm_resources,
      "(metadata->>'resource_id'), (metadata->>'child_id')",
      where: "internal_resource = 'Event' and metadata @> '{\"current\": [true]}'",
      unique: true,
      name: "index_orm_resources_on_current_event"
  end
end
