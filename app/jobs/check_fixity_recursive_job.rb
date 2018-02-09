# frozen_string_literal: true
class CheckFixityRecursiveJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  def perform
    file_set = query_service.custom_queries.least_recently_updated_file_set
    original_file_metadata = file_set.run_fixity
    file_set.file_metadata = file_set.file_metadata.select { |x| !x.original_file? } + Array.wrap(original_file_metadata)
    metadata_adapter.persister.save(resource: file_set)
    CheckFixityRecursiveJob.set(queue: queue_name).perform_later
  end

  private

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end
end
