# frozen_string_literal: true
class CheckFixityRecursiveJob < ApplicationJob
  queue_as :super_low
  delegate :query_service, to: :metadata_adapter

  def perform
    LocalFixityJob.perform_now(next_file_set.id)
    CheckFixityRecursiveJob.perform_later
  end

  private

    def next_file_set
      query_service.custom_queries.file_sets_sorted_by_updated(limit: 1).first
    end

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end
end
