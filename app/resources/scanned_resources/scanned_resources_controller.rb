# frozen_string_literal: true
class ScannedResourcesController < ResourceController
  self.resource_class = ScannedResource
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )

  def after_create_success(obj, change_set)
    super
    handle_save_and_ingest(obj)
  end

  def handle_save_and_ingest(obj)
    return unless params[:save_and_ingest_path].present?
    locator = IngestFolderLocator.new(id: params[:scanned_resource][:source_metadata_identifier], search_directory: ingest_folder)
    IngestFolderJob.perform_later(directory: locator.root_path.join(params[:save_and_ingest_path]).to_s, property: "id", id: obj.id.to_s)
  end

  # View the structural metadata for a given repository resource
  def structure
    @change_set = ChangeSet.for(find_resource(params[:id]), change_set_param: change_set_param).prepopulate!
    authorize! :structure, @change_set.resource
    @logical_order = (Array(@change_set.logical_structure).first || Structure.new).decorate
    members = Wayfinder.for(@change_set.resource).members_with_parents
    @logical_order = WithProxyForObject.new(@logical_order, members)
  end

  # Render the IIIF presentation manifest for a given repository resource
  def manifest
    @resource = find_resource(params[:id])
    authorize! :manifest, @resource
    respond_to do |f|
      f.json do
        render json: cached_manifest(@resource, auth_token_param)
      end
    end
  rescue Valkyrie::Persistence::ObjectNotFoundError
    @resource = query_service.custom_queries.find_by_local_identifier(local_identifier: params[:id]).first
    raise Valkyrie::Persistence::ObjectNotFoundError unless @resource
    redirect_to manifest_scanned_resource_path(id: @resource.id.to_s)
  end

  def cached_manifest(resource, auth_token_param)
    Rails.cache.fetch("#{ManifestKey.for(resource)}/#{auth_token_param}") do
      ManifestBuilder.new(resource, auth_token_param).build.to_json
    end
  end

  def pdf
    change_set = ChangeSet.for(find_resource(params[:id]), change_set_param: change_set_param)
    authorize! :pdf, change_set.resource
    pdf_file = PDFService.new(change_set_persister).find_or_generate(change_set)

    redirect_path_args = { resource_id: change_set.id, id: pdf_file.id }
    redirect_path_args[:auth_token] = auth_token_param if auth_token_param
    redirect_to download_path(redirect_path_args)
  end

  # API endpoint for asking where a folder to save and ingest from is located.
  def save_and_ingest
    authorize! :create, resource_class
    respond_to do |f|
      f.json do
        render json: IngestFolderLocator.new(id: params[:id], search_directory: ingest_folder).to_h
      end
    end
  end

  private

    def auth_token_param
      params[:auth_token]
    end

    def ingest_folder
      if change_set_param.eql? "recording"
        "music"
      else
        Figgy.config["default_search_directory"]
      end
    end
end
