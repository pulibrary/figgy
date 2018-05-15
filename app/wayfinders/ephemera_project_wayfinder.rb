# frozen_string_literal: true
class EphemeraProjectWayfinder < BaseWayfinder
  relationship_by_property :members, property: :member_ids
  relationship_by_property :ephemera_boxes, property: :member_ids, model: EphemeraBox
  relationship_by_property :ephemera_folders, property: :member_ids, model: EphemeraFolder
  relationship_by_property :ephemera_fields, property: :member_ids, model: EphemeraField
  inverse_relationship_by_property :templates, property: :parent_id

  def ephemera_folders_count
    @ephemera_folders_count ||= query_service.custom_queries.count_members(resource: resource, model: EphemeraFolder)
  end
end
