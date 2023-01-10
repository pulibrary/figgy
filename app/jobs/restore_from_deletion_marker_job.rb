# frozen_string_literal: true
class RestoreFromDeletionMarkerJob < ApplicationJob
  queue_as :default
  delegate :query_service, to: :metadata_adapter

  def perform(deletion_marker_id)
    DeletionMarkerService.restore(deletion_marker_id)
  end
end
