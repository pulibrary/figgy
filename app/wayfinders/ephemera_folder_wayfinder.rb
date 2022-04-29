# frozen_string_literal: true
class EphemeraFolderWayfinder < BaseWayfinder
  inverse_relationship_by_property :parents, property: :member_ids, singular: true
  inverse_relationship_by_property :ephemera_boxes, property: :member_ids, singular: true, model: EphemeraBox
  inverse_relationship_by_property :ephemera_projects, property: :member_ids, singular: true, model: EphemeraProject
  relationship_by_property :members, property: :member_ids
  relationship_by_property :file_sets, property: :member_ids, model: FileSet
  relationship_by_property :collections, property: :member_of_collection_ids

  # Boxless folders shouldn't go through a box for their project.
  # TODO: Move boxless folders to a new model?
  alias original_ephemera_projects ephemera_projects
  def ephemera_projects
    @delegated_ephemera_projects ||= ephemera_box.present? ? Wayfinder.for(ephemera_box).ephemera_projects : original_ephemera_projects
  end

  def members_with_parents
    @members_with_parents ||= members.map do |member|
      member.loaded[:parents] = [resource]
      member
    end
  end
end
