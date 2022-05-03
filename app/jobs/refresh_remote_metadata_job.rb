# frozen_string_literal: true

class RefreshRemoteMetadataJob < ApplicationJob
  queue_as :low
  delegate :query_service, to: :change_set_persister
  attr_reader :change_set, :imported_metadata

  def perform(id:)
    @change_set = ChangeSet.for(query_service.find_by(id: id))
    @imported_metadata = change_set.model.primary_imported_metadata
    apply_remote_metadata
    return unless changed?
    change_set_persister.save(change_set: change_set)
  end

  private

    def change_set_persister
      ChangeSetPersister.default
    end

    def apply_remote_metadata
      change_set.refresh_remote_metadata = "1"
      ChangeSetPersister::ApplyRemoteMetadata.new(change_set_persister: change_set_persister, change_set: change_set).run
    end

    def changed?
      imported_metadata.to_h != change_set.model.primary_imported_metadata.to_h
    end
end
