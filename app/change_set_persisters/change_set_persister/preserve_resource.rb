class ChangeSetPersister
  class PreserveResource
    attr_reader :change_set_persister, :change_set, :post_save_resource
    delegate :metadata_adapter, :query_service, to: :change_set_persister
    delegate :append_id, to: :change_set

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

      # If this resource was just added to a new parent, preserve the parent.
      if append_id.present?
        lock_tokens = new_parent.optimistic_lock_token.map(&:serialize)
        PreserveResourceJob.perform_later(id: append_id.to_s, lock_tokens: lock_tokens)
      end

      # Even if the resource has a new parent, preserve it, because the parent
      # only preserves its children if they've never been preserved before.

      # Pass the current lock tokens to the job so we can ensure we only
      # preserve the resource in that job if it hasn't changed since then.
      lock_tokens = cs[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK] || []
      lock_tokens = lock_tokens.map(&:serialize)
      PreserveResourceJob.perform_later(id: cs.id.to_s, lock_tokens: lock_tokens)
    end

    def new_parent
      @new_parent ||= query_service.find_by(id: append_id)
    end

    def reload(resource)
      query_service.find_by(id: resource.id)
    rescue Valkyrie::Persistence::ObjectNotFoundError
      resource
    end
  end
end
