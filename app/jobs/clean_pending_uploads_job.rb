# frozen_string_literal: true
class CleanPendingUploadsJob < ApplicationJob
  def perform(dry_run: false)
    query_service.custom_queries.find_pending_upload_failures.each do |resource|
      change_set_persister.buffer_into_index do |buffered_changeset_persister|
        if resource.respond_to?(:pending_uploads) && resource.pending_uploads.empty? && resource.state.include?("pending")
          change_set = DynamicChangeSet.new(resource)
          if dry_run
            Valkyrie.logger.info("Found #{resource.id} as an uploaded resource without any FileSets - this would normally be deleted by CleanPendingUploadsJob")
          else
            buffered_changeset_persister.delete(change_set: change_set)
          end
          Valkyrie.logger.info "Deleted a resource with failed uploads with the ID: #{resource.id}"
        end
      end
    end
  end

  private

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end
    delegate :query_service, to: :metadata_adapter

    def change_set_persister
      @change_set_persister ||= ChangeSetPersister.new(
        metadata_adapter: metadata_adapter,
        storage_adapter: Valkyrie.config.storage_adapter
      )
    end
end
