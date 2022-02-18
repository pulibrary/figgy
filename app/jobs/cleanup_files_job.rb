# frozen_string_literal: true

class CleanupFilesJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  def perform(file_identifiers:)
    file_identifiers.each do |file_identifier|
      storage_adapter = Valkyrie::StorageAdapter.adapter_for(id: file_identifier)
      # Delete the given ID.
      storage_adapter.delete(id: file_identifier.to_s)
      # Delete the entire directory to remove unzipped derivatives like display vectors
      #
      # This relies on a quirk of the Disk storage adapter to remove the
      # hierarchy. It won't do anything in cloud storage, but that's fine
      # because there are no "directories" in GCS, just files with names that
      # pretend they're directories.
      id = File.dirname(file_identifier.to_s)
      storage_adapter.delete(id: id)
    end
  end
end
