# frozen_string_literal: true
class ScannedResourcesController < BaseResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = ScannedResource
  self.change_set_persister = ::PlumChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )

  # manifest thing
  def structure
    @change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
    @logical_order = (Array(@change_set.logical_structure).first || Structure.new).decorate
    @logical_order = WithProxyForObject.new(@logical_order, query_service.find_members(resource: @change_set.id).to_a)
    authorize! :structure, @change_set.resource
  end

  def manifest
    @resource = find_resource(params[:id])
    authorize! :manifest, @resource
    respond_to do |f|
      f.json do
        render json: ManifestBuilder.new(@resource).build
      end
    end
  end

  def pdf
    change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
    authorize! :pdf, change_set.resource
    pdf_file = PDFGenerator.new(resource: change_set.resource, storage_adapter: Valkyrie::StorageAdapter.find(:derivatives)).render
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      change_set.validate(file_metadata: [pdf_file])
      change_set.sync
      buffered_changeset_persister.save(change_set: change_set)
    end
    redirect_to valhalla.download_path(resource_id: change_set.id, id: pdf_file.id)
  end
end
