# frozen_string_literal: true

class VectorResourcesController < ResourceController
  include GeoResourceController
  include GeoblacklightDocumentController
  before_action :load_thumbnail_members, only: [:edit]

  self.resource_class = VectorResource
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )

  def load_thumbnail_members
    @thumbnail_members = resource.decorate.thumbnail_members
  end
end
