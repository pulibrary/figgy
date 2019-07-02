# frozen_string_literal: true

class ChangeSetPersister
  class PreserveResource
    attr_reader :change_set_persister, :change_set, :post_save_resource
    delegate :metadata_adapter, to: :change_set_persister

    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @post_save_resource = post_save_resource
    end

    def run
      cs = change_set.class.new(post_save_resource)
      return unless cs.try(:preserve?)
      # It's important that we inline this for parents, to ensure that a race
      # condition doesn't happen which makes it so that two jobs get queued up
      # that each call PreserveChildrenJob, resulting in multiple file uploads
      if cs.try(:member_ids).present?
        PreserveResourceJob.perform_now(id: cs.id.to_s)
      else
        PreserveResourceJob.perform_later(id: cs.id.to_s)
      end
    end
  end
end
