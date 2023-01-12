# frozen_string_literal: true
class AddUniquePreservationObjectIndex < ActiveRecord::Migration[6.1]
  # Add a unique index to PreservationObjects so there can only ever be one per
  # resource.
  def change
    add_index :orm_resources, "(metadata->>'preserved_object_id')", where: "internal_resource = 'PreservationObject'", unique: true
  end
end
