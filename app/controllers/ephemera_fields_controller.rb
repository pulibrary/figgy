# frozen_string_literal: true
class EphemeraFieldsController < ApplicationController
  include Valhalla::ResourceController
  include TokenAuth
  self.change_set_class = DynamicChangeSet
  self.resource_class = EphemeraField
  self.change_set_persister = ::PlumChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
end
