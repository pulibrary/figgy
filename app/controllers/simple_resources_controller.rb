# frozen_string_literal: true

# A base controller for resources, intended for inheritance
class SimpleResourcesController < BaseResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = SimpleResource
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )

  # Render the IIIF presentation manifest for a given repository resource
  def manifest
    @resource = find_resource(params[:id])
    authorize! :manifest, @resource
    respond_to do |f|
      f.json do
        render json: ManifestBuilder.new(@resource).build
      end
    end
  rescue Valkyrie::Persistence::ObjectNotFoundError
    @resource = query_service.custom_queries.find_by_local_identifier(local_identifier: params[:id]).first
    raise Valkyrie::Persistence::ObjectNotFoundError unless @resource
    redirect_to manifest_simple_resource_path(id: @resource.id.to_s)
  end

  def pdf
    change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
    authorize! :pdf, change_set.resource

    pdf_file = PDFGenerator.new(resource: change_set.resource, storage_adapter: Valkyrie::StorageAdapter.find(:derivatives)).render
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      change_set.validate(file_metadata: [pdf_file])
      buffered_changeset_persister.save(change_set: change_set)
    end
    redirect_to valhalla.download_path(resource_id: change_set.id, id: pdf_file.id)
  end
end
