# frozen_string_literal: true
class VectorResourcesController < BaseResourceController
  include GeoResourceController
  include GeoblacklightDocumentController

  self.change_set_class = DynamicChangeSet
  self.resource_class = VectorResource
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
end
