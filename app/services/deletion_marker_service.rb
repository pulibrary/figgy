# frozen_string_literal: true

class DeletionMarkerService
  def self.restore(deletion_marker_id)
    new(deletion_marker_id: deletion_marker_id).restore
  end

  attr_reader :deletion_marker_id
  def initialize(deletion_marker_id:)
    @deletion_marker_id = deletion_marker_id
  end

  def restore
    deletion_marker = query_service.find_by(id: Valkyrie::ID.new(deletion_marker_id))
    restore_from_deletion_marker(deletion_marker)
  end

  private

    def restore_from_deletion_marker(deletion_marker)
      return unless deletion_marker && deletion_marker.preservation_object.present?

      resource = Preserver::Importer.from_preservation_object(
        resource: deletion_marker.preservation_object,
        change_set_persister: change_set_persister
      )

      attach_to_parent(parent_id: deletion_marker.parent_id, resource: resource)
      restore_members(resource)
      # Characterize and run derivatives on FileSets
      CharacterizationJob.perform_later(resource.id.to_s) if resource.is_a?(FileSet)
      change_set_persister.delete(change_set: ChangeSet.for(deletion_marker))
    end

    def restore_members(resource)
      resource.try(:member_ids)&.each do |member_id|
        member_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(member_id))&.first
        restore_from_deletion_marker(member_deletion_marker) if member_deletion_marker
      end
    end

    def attach_to_parent(parent_id:, resource:)
      return if parent_id.blank?
      parent = query_service.find_by(id: Valkyrie::ID.new(parent_id))
      change_set = ChangeSet.for(parent)
      change_set.member_ids += [resource.id]
      change_set.sync
      change_set_persister.save(change_set: change_set)
    end

    def change_set_persister
      ChangeSetPersister.default
    end

    def query_service
      change_set_persister.metadata_adapter.query_service
    end
end
