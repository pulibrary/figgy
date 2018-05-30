# frozen_string_literal: true
class RasterResourcesController < BaseResourceController
  include GeoResourceController
  include GeoblacklightDocumentController
  before_action :load_thumbnail_members, only: [:edit]

  self.change_set_class = DynamicChangeSet
  self.resource_class = RasterResource
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )

  def load_thumbnail_members
    @thumbnail_members = resource.decorate.thumbnail_members
  end
end
