# frozen_string_literal: true
class EphemeraBoxesController < ApplicationController
  include Valhalla::ResourceController
  include TokenAuth
  self.change_set_class = DynamicChangeSet
  self.resource_class = EphemeraBox
  self.change_set_persister = ::PlumChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
  before_action :load_collections, only: [:new, :edit]

  private

    def load_collections
      @collections = query_service.find_all_of_model(model: Collection).map(&:decorate)
    end
end
