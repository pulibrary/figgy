# frozen_string_literal: true
class PreserveChildrenJob < ApplicationJob
  delegate :metadata_adapter, to: :change_set_persister
  delegate :query_service, to: :metadata_adapter

  def perform(id:, unpreserved_only: true)
    resource = query_service.find_by(id: id)
    ids = if unpreserved_only
            query_service.custom_queries.find_never_preserved_child_ids(resource: resource)
          else
            resource.member_ids || []
          end
    ids.each do |member_id|
      member = query_service.find_by(id: member_id)
      lock_tokens = member[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK] || []
      lock_tokens = lock_tokens.map(&:serialize)
      PreserveResourceJob.perform_later(id: member_id.to_s, lock_tokens: lock_tokens)
    end
  rescue Valkyrie::Persistence::ObjectNotFoundError
    Rails.logger.info "Object not found: #{id}"
  end

  def change_set_persister
    ChangeSetPersister.default
  end
end
