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
    # calculate the path, including fingerprint
    # check to see if it exists in s3
    # if so, return the path
    # if not, generate it and return the new path

    # path = Valkyrie::Storage::Disk::BucketedStorage.new(base_path: "s3://figgy-geo-staging").generate(resource: resource, original_filename: "mosaic.json", file: nil)

    mosaic_path = MosaicGenerator.new(resource: resource).generate
    respond_to do |f|
      f.json do
        render json: { uri: mosaic_path }
      end
    end
  end
end
