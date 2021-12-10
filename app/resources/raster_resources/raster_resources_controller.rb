# frozen_string_literal: true
class RasterResourcesController < ResourceController
  include GeoResourceController
  include GeoblacklightDocumentController
  before_action :load_thumbnail_members, only: [:edit]

  self.resource_class = RasterResource
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )

  def load_thumbnail_members
    @thumbnail_members = resource.decorate.thumbnail_members
  end

  def mosaic
    cloud_persister = ::ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:geo_derivatives)
    )

    change_set = ChangeSet.for(find_resource(params[:id]), change_set_param: change_set_param)
    # authorize! :mosaic, change_set.resource
    mosaic_file = MosaicService.new(cloud_persister).find_or_generate(change_set)

    redirect_path_args = { resource_id: change_set.id, id: mosaic_file.id }
    redirect_to download_path(redirect_path_args)
  end
end
