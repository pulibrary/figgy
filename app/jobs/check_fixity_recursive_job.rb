# frozen_string_literal: true
class CheckFixityRecursiveJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  def perform
    CheckFixityJob.perform_now(next_file_set.id)
    CheckFixityRecursiveJob.set(queue: :super_low).perform_later
  end

  private

    def next_file_set
      query_service.custom_queries.file_sets_sorted_by_updated(limit: 1).first
    end

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end
end
