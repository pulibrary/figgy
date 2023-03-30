# frozen_string_literal: true
# Allows backgrounding of server uploads, for when a ton of files are selected
# to be uploaded.
class ServerUploadJob < ApplicationJob
  def perform(resource_id, pending_upload_ids)
    pending_upload_ids.each_slice(10) do |pending_upload_slice|
      change_set_persister.buffer_into_index do |buffered_change_set_persister|
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

  def change_set_persister
    ChangeSetPersister.default
  end
end
