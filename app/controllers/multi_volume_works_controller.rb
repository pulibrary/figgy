# frozen_string_literal: true
class MultiVolumeWorksController < ScannedResourcesController
  self.change_set_class = DynamicChangeSet
  self.resource_class = MultiVolumeWork
  self.change_set_persister = ::PlumChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
end
