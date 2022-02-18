# frozen_string_literal: true

class PreserveChildrenJob < ApplicationJob
  delegate :metadata_adapter, to: :change_set_persister
  delegate :query_service, to: :metadata_adapter

  def perform(id:)
    resource = query_service.find_by(id: id)
    (resource.try(:member_ids) || []).each do |member_id|
      PreserveResourceJob.perform_later(id: member_id.to_s)
    end
  rescue Valkyrie::Persistence::ObjectNotFoundError
    Rails.logger.info "Object not found: #{id}"
  end

  def change_set_persister
    ChangeSetPersister.default
  end
end
