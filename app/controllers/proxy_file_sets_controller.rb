# frozen_string_literal: true

class ProxyFileSetsController < ResourceController
  self.resource_class = ProxyFileSet
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
end
