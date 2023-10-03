# frozen_string_literal: true
class AddUniqueMetadataEventIndex < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :orm_resources,
      "(metadata->>'resource_id'), (metadata->>'type')",
      where: "internal_resource = 'Event' and metadata @> '{\"current\": [true], \"type\": [\"metadata_node\"]}'",
      unique: true,
      name: "index_orm_resources_on_current_metadata_event",
      algorithm: :concurrently
  end
end
