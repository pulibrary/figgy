# frozen_string_literal: true
class BrowseEverythingIngestJob < ApplicationJob
  def perform(resource_id, controller_scope_string, pending_upload_ids)
    controller_scope = controller_scope_string.constantize
    change_set_persister = controller_scope.change_set_persister
    change_set_class = controller_scope.change_set_class
    pending_upload_ids = pending_upload_ids.map { |x| Valkyrie::Types::ID[x] }
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      resource = buffered_changeset_persister.metadata_adapter.query_service.find_by(id: Valkyrie::ID.new(resource_id))
      change_set = change_set_class.new(resource)
      selected_files = resource.pending_uploads.select do |pending_upload|
        pending_upload_ids.include?(pending_upload.id)
      end
      change_set.validate(files: selected_files)
      buffered_changeset_persister.save(change_set: change_set)
    end
  end
end
