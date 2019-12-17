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
    resource = change_set_persister.metadata_adapter.query_service.find_by(id: Valkyrie::ID.new(resource_id))
    pending_uploads = resource.pending_uploads.select { |upload| pending_upload_ids.include?(upload.id.to_s) }

    # This is used to store the IDs for the files being uploaded
    upload_ids = []
    # This is used to filter the pending uploads which were just containers/directories
    remaining_uploads = []
    pending_uploads.each do |upload|
      if upload.container?

        file_attributes = {
          id: upload.local_id.first,
          container: upload.container?,
          provider: upload.provider.first
        }

        unless upload.auth_token.nil?
          file_attributes[:auth_token] = upload.auth_token.first
          file_attributes[:auth_header] = upload.auth_header
        end

        retriever = BrowseEverything::Retriever.new
        member_resources = retriever.member_resources(file_attributes)
        provider = BrowseEverything::Retriever.build_provider(upload.provider.first)
        # Create the new uploads
        member_uploads = member_resources.map do |member_file|
          member_attributes = {
            local_id: member_file[:id],
            file_name: member_file[:file_name],
            file_size: member_file[:file_size],
            url: member_file[:url],
            type: member_file[:container] ? "container" : "file",
            provider: member_file[:provider]
          }

          if member_file.key?(:auth_token)
            # This uses the provider constructed for the parent container
            file_auth_header = provider.class.authorization_header(member_file[:auth_token])

            member_attributes[:auth_token] = member_file[:auth_token]
            member_attributes[:auth_header] = file_auth_header
          end

          PendingUpload.new(
            member_attributes.merge(
              id: SecureRandom.uuid,
              created_at: Time.current.utc.iso8601
            )
          )
        end

        # Persist the new uploads
        change_set_persister.buffer_into_index do |buffered_change_set_persister|
          change_set = change_set_class.new(resource)
          change_set.validate(pending_uploads: change_set.pending_uploads + member_uploads)
          buffered_change_set_persister.save(change_set: change_set)
        end

        upload_ids += member_uploads.map(&:id)
      else
        upload_ids << upload.id
        remaining_uploads << upload
      end
    end

    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      change_set = change_set_class.new(resource)
      selected_files = resource.pending_uploads.select do |pending_upload|
        upload_ids.include?(pending_upload.id) && !pending_upload.container?
      end

      # Set the files to the pending uploads
      change_set.validate(pending_uploads: remaining_uploads, files: selected_files)
      buffered_changeset_persister.save(change_set: change_set)
    end
  rescue Valkyrie::Persistence::ObjectNotFoundError
    Valkyrie.logger.warn "Unable to find resource with ID: #{resource_id}"
  end
end
