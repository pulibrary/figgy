# frozen_string_literal: true
class CheckFixityRecursiveJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  def perform
    file_set = find_next_file_to_check
    original_file_metadata = file_set.run_fixity
    file_set.file_metadata = file_set.file_metadata.select { |x| !x.original_file? } + Array.wrap(original_file_metadata)
    metadata_adapter.persister.save(resource: file_set)
    CheckFixityRecursiveJob.set(queue: queue_name).perform_later
  end

  private

    def find_next_file_to_check
      query_service.find_all_of_model(model: FileSet).map(&:decorate).sort_by(&:fixity_sort_date).first
    end

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end
end
