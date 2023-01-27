# frozen_string_literal: true
class PreserveChildrenJob < ApplicationJob
  delegate :metadata_adapter, to: :change_set_persister
  delegate :query_service, to: :metadata_adapter

  def perform(id:)
    resource = query_service.find_by(id: id)
    unpreserved_ids = query_service.custom_queries.find_never_preserved_child_ids(resource: resource)
    unpreserved_ids.each do |member_id|
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
