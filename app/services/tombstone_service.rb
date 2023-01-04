# frozen_string_literal: true

class TombstoneService
  def self.restore(tombstone_id)
    new(tombstone_id: tombstone_id).restore
  end

  attr_reader :tombstone_id
  def initialize(tombstone_id:)
    @tombstone_id = tombstone_id
  end

  def restore
    tombstone = query_service.find_by(id: Valkyrie::ID.new(tombstone_id))
    restore_from_tombstone(tombstone)
  end

  private

    def restore_from_tombstone(tombstone)
      return unless tombstone && tombstone.preservation_object.present?

      resource = Preserver::Importer.from_preservation_object(
        resource: tombstone.preservation_object,
        change_set_persister: change_set_persister
      )

      attach_to_parent(parent_id: tombstone.parent_id, resource: resource)
      restore_members(resource)
      change_set_persister.delete(change_set: ChangeSet.for(tombstone))
    end

    def restore_members(resource)
      resource.try(:member_ids)&.each do |member_id|
        member_tombstone = query_service.custom_queries.find_by_property(property: :file_set_id, value: Valkyrie::ID.new(member_id))&.first
        restore_from_tombstone(member_tombstone) if member_tombstone
      end
    end

    def attach_to_parent(parent_id:, resource:)
      return if parent_id.blank?
      parent = query_service.find_by(id: Valkyrie::ID.new(parent_id))
      change_set = ChangeSet.for(parent)
      change_set.member_ids += [resource.id]
      change_set.sync
      change_set.created_file_sets += [resource] if resource.is_a? FileSet
      change_set_persister.save(change_set: change_set)
    end

    def change_set_persister
      ChangeSetPersister.default
    end

    def query_service
      change_set_persister.metadata_adapter.query_service
    end
end
