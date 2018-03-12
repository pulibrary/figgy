# frozen_string_literal: true
class CheckFixityRecursiveJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  def perform
    file_set = query_service.custom_queries.file_sets_sorted_by_updated(limit: 1).first
    CheckFixityJob.perform_now(file_set.id)
    CheckFixityRecursiveJob.set(queue: queue_name).perform_later
  end

  private

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end
end
