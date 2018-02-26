# frozen_string_literal: true
class BrowseEverythingIngestJob < ApplicationJob
  # Download and append the pending uploads to a given resource
  # @param resource_id [String] the ID of the Valkyrie resource
  # @param controller_scope_string [String] the name of the Controller in which this is invoked
  # @param pending_upload_ids [Array<String>] the IDs of the files pending upload
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
      # Set the files to the pending uploads
      change_set.validate(files: selected_files)
      buffered_changeset_persister.save(change_set: change_set)
    end
  end
end
