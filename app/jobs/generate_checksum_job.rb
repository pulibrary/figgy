# frozen_string_literal: true
class GenerateChecksumJob < ApplicationJob
  delegate :query_service, :persister, to: :metadata_adapter

  def perform(file_set_id)
    file_set = query_service.find_by(id: Valkyrie::ID.new(file_set_id))
    file_set.preservation_targets.each do |target|
      next if target.checksum.present?
      target.checksum = target.file_identifiers.map do |id|
        MultiChecksum.for(Valkyrie::StorageAdapter.find_by(id: id))
      end
    end
    persister.save(resource: file_set)
  end

  def metadata_adapter
    Valkyrie::MetadataAdapter.find(:indexing_persister)
  end
end
