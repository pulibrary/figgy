# frozen_string_literal: true
class CleanupFilesJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  def perform(file_identifiers:)
    file_identifiers.each do |file_identifier|
      storage_adapter = Valkyrie::StorageAdapter.adapter_for(id: file_identifier)
      storage_adapter.delete(id: file_identifier.to_s)
      # Delete the entire directory to remove unzipped derivatives like display vectors
      # This will just not do anything on cloud storage.
      id = File.dirname(file_identifier.to_s)
      storage_adapter.delete(id: id)
    end
  end
end
