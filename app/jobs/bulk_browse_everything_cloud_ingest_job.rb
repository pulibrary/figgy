# frozen_string_literal: true
class BulkBrowseEverythingCloudIngestJob < ApplicationJob
  queue_as :low
  delegate :query_service, to: :metadata_adapter

  def perform(upload_set_ids:, resource_class:)
    upload_sets = upload_set_ids.map do |upload_id|
      BrowseEverything::Upload.find_by(uuid: upload_id).first
    end
    resource_class = resource_class.constantize
    BulkCloudIngester.new(change_set_persister: change_set_persister, upload_sets: upload_sets, resource_class: resource_class).ingest
  end

  private

    def change_set_persister
      @change_set_persister ||= ChangeSetPersister.new(
        metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
        storage_adapter: Valkyrie.config.storage_adapter
      )
    end
end
