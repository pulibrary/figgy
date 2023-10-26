# frozen_string_literal: true
class Migrations::MetadataRepreserver
  def self.run!
    new.run!
  end

  def run!
    all_preservation_objects.each do |po|
      next if po.metadata_version.present?
      resource = Wayfinder.for(po).preserved_resource
      # If we've enabled optimistic locking after a resource was saved, use this
      # chance to generate a lock token.
      if resource.optimistic_locking_enabled? && resource.optimistic_lock_token.blank?
        resource = ChangeSetPersister.default.metadata_adapter.persister.save(resource: resource)
      end
      lock_tokens = (resource[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK] || []).map(&:serialize)
      PreserveResourceJob.set(queue: :super_low).perform_later(id: resource.id.to_s, lock_tokens: lock_tokens)
    end
  end

  def all_preservation_objects
    ChangeSetPersister.default.query_service.custom_queries.find_by_property(model: PreservationObject, property: :preserved_object_id, value: [], lazy: true)
  end
end
