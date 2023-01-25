# frozen_string_literal: true
class PreserveResourceJob < ApplicationJob
  queue_as :low
  delegate :metadata_adapter, to: :change_set_persister
  delegate :query_service, to: :metadata_adapter

  # @param id [String] resource id
  # @param lock_tokens [Array<String>] serialized lock tokens
  # @param force_preservation [Boolean] force binary node preservation
  def perform(id:, lock_tokens: nil, force_preservation: false)
    resource = query_service.find_by(id: id)
    # If two jobs get queued before this job runs once (forcing future
    # PreserveResourceJobs to run inline), then without this it would create two
    # PreservationObjects. Return early if the resource has changed since this
    # job was queued.
    return unless token_valid?(resource: resource, lock_tokens: lock_tokens)

    change_set_persister.buffer_into_index do |buffered_change_set_persister|
      change_set = ChangeSet.for(resource)
      Preserver.for(change_set: change_set, change_set_persister: buffered_change_set_persister, force_preservation: force_preservation).preserve!
    end
  rescue Valkyrie::Persistence::ObjectNotFoundError
    Rails.logger.info "Object not found: #{id}"
  end

  private

    def change_set_persister
      ChangeSetPersister.default
    end

    # If a resource has optimistic locking enabled, check if the lock tokens
    # passsed in as a Job parameter match the lock tokens on the resource.
    def token_valid?(resource:, lock_tokens:)
      if lock_tokens.present? && resource.optimistic_locking_enabled?
        resource_lock_tokens = resource[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK]
        return false if resource_lock_tokens != deserialize_tokens(lock_tokens)
      end

      true
    end

    # Deserialize lock tokens into OptimisticLockToken objects
    def deserialize_tokens(lock_tokens)
      lock_tokens.map do |lock_token|
        Valkyrie::Persistence::OptimisticLockToken.deserialize(lock_token)
      end
    end
end
