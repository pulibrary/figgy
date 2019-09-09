# frozen_string_literal: true

class RecordingDownloadableMigrator
  def self.call
    recordings = query_service.custom_queries.find_by_property(property: :change_set, value: "recording")
    playlists = query_service.find_all_of_model(model: Playlist)
    resources = recordings + playlists
    progress_bar = ProgressBar.create(
      format: "%a %e %P% Processed: %c from %C",
      total: resources.count
    )
    resources.each do |resource|
      change_set = ChangeSet.for(resource)
      change_set.validate(downloadable: "none")
      change_set_persister.save(change_set: change_set)
      progress_bar.progress += 1
    end
  end

  def self.metadata_adapter
    Valkyrie::MetadataAdapter.find(:indexing_persister)
  end

  def self.query_service
    metadata_adapter.query_service
  end

  def self.change_set_persister
    ChangeSetPersister.new(
      metadata_adapter: metadata_adapter,
      storage_adapter: Valkyrie::StorageAdapter.find(:disk)
    )
  end
end
