# frozen_string_literal: true
class CoinsController < BaseResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = Coin
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )

  def manifest
    authorize! :manifest, resource
    respond_to do |f|
      f.json do
        render json: ManifestBuilder.new(resource).build
      end
    end
  end

  # report whether there are files
  def discover_files
    authorize! :create, resource_class
    respond_to do |f|
      f.json do
        render json: file_locator.to_h
      end
    end
  end

  def auto_ingest
    authorize! :create, resource_class
    IngestFolderJob.perform_later(directory: file_locator.folder_pathname.to_s, property: "id", id: resource.id.to_s)
    redirect_to file_manager_coin_path(params[:id])
  end

  private

    def file_locator
      IngestFolderLocator.new(id: resource.coin_number, search_directory: "numismatics")
    end
end
