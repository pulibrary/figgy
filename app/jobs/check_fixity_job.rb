# frozen_string_literal: true
class CheckFixityJob < ApplicationJob
  queue_as :super_low
  delegate :query_service, to: :metadata_adapter

  def perform(file_set_id)
    file_set = query_service.find_by(id: Valkyrie::ID.new(file_set_id))
    original_file_metadata = file_set.run_fixity
    file_set.file_metadata = file_set.file_metadata.select { |x| !x.original_file? } + Array.wrap(original_file_metadata)
    metadata_adapter.persister.buffer_into_index do |buffered_adapter|
      buffered_adapter.persister.save(resource: file_set)
    end
  rescue Valkyrie::Persistence::ObjectNotFoundError => error
    Valkyrie.logger.warn "#{self.class}: #{error}: Failed to find the resource #{file_set_id}"
  rescue Valkyrie::StorageAdapter::FileNotFound
    # If there's no parent, and the file is gone, this is an orphan row in the
    # database, just delete it.
    raise if file_set.decorate.parent
    metadata_adapter.persister.delete(resource: file_set)
  end

  private

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end
end
