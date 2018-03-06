# frozen_string_literal: true
class RasterResourcesController < BaseResourceController
  include GeoResourceController
  include GeoblacklightDocumentController

  self.change_set_class = DynamicChangeSet
  self.resource_class = RasterResource
  self.change_set_persister = ::PlumChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
end
