# frozen_string_literal: true
# Allows backgrounding of server uploads, for when a ton of files are selected
# to be uploaded.
class ServerUploadJob < ApplicationJob
  def perform(resource_id, pending_upload_ids)
    pending_upload_ids.each_slice(10) do |pending_upload_slice|
      change_set_persister.buffer_into_index do |buffered_change_set_persister|
        # Prevent state propagation - file sets don't have state or visibility, and it's real
        # slow to do every 10 resources.
        buffered_change_set_persister.prevent_propagation!
        resource = buffered_change_set_persister.query_service.find_by(id: resource_id)
        attach_uploads = resource.pending_uploads.select do |upload|
          pending_upload_slice.include?(upload.id.to_s)
        end
        if attach_uploads.present?
          change_set = ChangeSet.for(resource)
          change_set.validate(files: attach_uploads)
          buffered_change_set_persister.save(change_set: change_set)
        end
      end
    end
  end

  # We have access to the files on disk, so copy them from their locations.
  def change_set_persister
    ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:disk_via_copy)
    )
  end
end
