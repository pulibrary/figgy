# frozen_string_literal: true
class ScannedResourcesController < BaseResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = ScannedResource
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )

  def edit
    if change_set.class == SimpleResourceChangeSet
      flash[:alert] = "Editing resources without imported metadata has been disabled while features are being added to support metadata from PUDL. Please contact us on Slack if you need help."
      redirect_to solr_document_path(params[:id])
    else
      super
    end
  end

  def after_create_success(obj, change_set)
    super
    handle_save_and_ingest(obj)
  end

  def change_set_class
    if params[:change_set] == "simple" || (resource_params && resource_params[:change_set] == "simple")
      SimpleResourceChangeSet
    elsif params[:change_set] == "recording" || (resource_params && resource_params[:change_set] == "recording")
      RecordingChangeSet
    else
      DynamicChangeSet
    end
  end

  def handle_save_and_ingest(obj)
    return unless params[:commit] == "Save and Ingest"
    locator = IngestFolderLocator.new(id: params[:scanned_resource][:source_metadata_identifier])
    IngestFolderJob.perform_later(directory: locator.folder_pathname.to_s, property: "id", id: obj.id.to_s)
  end

  # View the structural metadata for a given repository resource
  def structure
    @change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
    @logical_order = (Array(@change_set.logical_structure).first || Structure.new).decorate
    members = Wayfinder.for(@change_set.resource).members_with_parents
    @logical_order = WithProxyForObject.new(@logical_order, members)
    authorize! :structure, @change_set.resource
  end

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
    redirect_to manifest_scanned_resource_path(id: @resource.id.to_s)
  end

  def pdf
    change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
    authorize! :pdf, change_set.resource
    pdf_file = change_set.resource.pdf_file

    unless pdf_file && binary_exists_for?(pdf_file)
      pdf_file = PDFGenerator.new(resource: change_set.resource, storage_adapter: Valkyrie::StorageAdapter.find(:derivatives)).render
      change_set_persister.buffer_into_index do |buffered_changeset_persister|
        change_set.validate(file_metadata: [pdf_file])
        buffered_changeset_persister.save(change_set: change_set)
      end
    end
    redirect_to download_path(resource_id: change_set.id, id: pdf_file.id)
  end

  def save_and_ingest
    authorize! :create, resource_class
    respond_to do |f|
      f.json do
        render json: save_and_ingest_response
      end
    end
  end

  def save_and_ingest_response
    locator = IngestFolderLocator.new(id: params[:id])
    {
      exists: locator.exists?,
      location: locator.location,
      file_count: locator.file_count,
      volume_count: locator.volume_count
    }
  end

  private

    def storage_adapter
      Valkyrie.config.storage_adapter
    end

    def binary_exists_for?(file_desc)
      pdf_file_binary = storage_adapter.find_by(id: file_desc.file_identifiers.first)
      !pdf_file_binary.nil?
    rescue Valkyrie::StorageAdapter::FileNotFound => error
      Valkyrie.logger.error("Failed to locate the file for the PDF FileMetadata: #{file_desc.file_identifiers.first}: #{error}")
      false
    end
end
