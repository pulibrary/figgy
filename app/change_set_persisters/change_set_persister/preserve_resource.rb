# frozen_string_literal: true

class ChangeSetPersister
  class PreserveResource
    attr_reader :change_set_persister, :change_set, :post_save_resource
    delegate :metadata_adapter, :query_service, to: :change_set_persister

    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @post_save_resource = post_save_resource
    end

    def run
      # Reload the resource because some after_save change_set persisters, like
      # AppendToParent, update the resource which changes the lock token value.
      cs = change_set.class.new(reload(post_save_resource))
      return unless cs.try(:preserve?)

      lock_tokens = cs[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK] || []
      lock_tokens = lock_tokens.map(&:serialize)

      # It's important that we inline this for parents, to ensure that a race
      # condition doesn't happen which makes it so that two jobs get queued up
      # that each call PreserveChildrenJob, resulting in multiple file uploads
      if cs.try(:member_ids).present?
        PreserveResourceJob.perform_now(id: cs.id.to_s, lock_tokens: lock_tokens)
      else
        PreserveResourceJob.perform_later(id: cs.id.to_s, lock_tokens: lock_tokens)
      end
    end

    def reload(resource)
      query_service.find_by(id: resource.id)
    rescue Valkyrie::Persistence::ObjectNotFoundError
      resource
    end
  end
end
