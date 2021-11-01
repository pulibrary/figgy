# frozen_string_literal: true

class UpdateDaoJob < ApplicationJob
  def perform(id)
    change_set = ChangeSet.for(change_set_persister.metadata_adapter.query_service.find_by(id: id))
    DaoUpdater.new(change_set: change_set, change_set_persister: change_set_persister).update!
  rescue Aspace::Client::ArchivalObjectNotFound => error
    Rails.logger.error("Archival object not found: #{error}")
  end

  private

    def change_set_persister
      @change_set_persister ||= ChangeSetPersister.new(
        metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
        storage_adapter: Valkyrie.config.storage_adapter
      )
    end
end
