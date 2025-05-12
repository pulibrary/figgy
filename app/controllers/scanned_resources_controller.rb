# frozen_string_literal: true
class ScannedResourcesController < ResourcesController
  self.resource_class = ScannedResource
  self.change_set_persister = ChangeSetPersister.default

  include Pdfable

  def after_create_success(obj, change_set)
    super
    handle_save_and_ingest(obj)
  end

  def handle_save_and_ingest(obj)
    return unless params[:save_and_ingest_path].present? && params[:commit] == "Save and Ingest"
    locator = IngestFolderLocator.new(id: params[:scanned_resource][:source_metadata_identifier], search_directory: ingest_folder)
    IngestFolderJob.perform_later(directory: locator.root_path.join(params[:save_and_ingest_path]).to_s, property: "id", id: obj.id.to_s)
  end

  def struct_manager
    @change_set = ChangeSet.for(find_resource(params[:id]), change_set_param: change_set_param).prepopulate!
    authorize! :structure, @change_set.resource
    @logical_order = (Array(@change_set.logical_structure).first || Structure.new).decorate
    members = Wayfinder.for(@change_set.resource).members_with_parents
    @logical_order = WithProxyForObject.new(@logical_order, members)
  end

  # View the structural metadata for a given repository resource
  def structure
    @change_set = ChangeSet.for(find_resource(params[:id])).prepopulate!
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
  end

  def cached_manifest(resource, auth_token_param)
    Rails.cache.fetch("#{ManifestKey.for(resource)}/#{auth_token_param}") do
      builder_klass = if Wayfinder.for(resource).first_member.try(:av?)
                        ManifestBuilderV3
                      else
                        ManifestBuilder
                      end
      builder_klass.new(resource, auth_token_param).build.to_json
    end
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

  def around_delete_action
    # Only allow deleting recordings whose tracks are not in playlists.
    playlists = if @change_set.is_a?(RecordingChangeSet)
                  Wayfinder.for(@change_set.resource).playlists
                else
                  []
                end
    if playlists.count.positive?
      playlist_ids = playlists.map(&:id).join(", ")
      flash[:alert] = "Unable to delete a recording with tracks in a playlist. Please remove this recording's tracks from the following playlists: #{playlist_ids}"
      redirect_to solr_document_path(@change_set.resource.id.to_s)
    else
      yield
    end
  end

  private

    def auth_token_param
      params[:auth_token]
    end

    def ingest_folder
      if change_set_param.eql? "recording"
        Figgy.config["music_search_directory"]
      else
        Figgy.config["default_search_directory"]
      end
    end
end
