# frozen_string_literal: true
class PlaylistsController < ResourcesController
  self.resource_class = Playlist
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )

  def resource_params
    return super unless params[:recording_id]
    {
      title: "Playlist: #{recording.title.first}",
      file_set_ids: recording.member_ids,
      part_of: recording.part_of
    }
  end

  def recording
    @recording ||= query_service.find_by(id: params[:recording_id])
  end

  # Render the IIIF presentation manifest for a given repository resource
  def manifest
    @resource = find_resource(params[:id])
    authorize! :manifest, @resource
    response.headers["Link"] = "<#{manifest_playlist_url(@resource)}>; rel=\"self\"; title=\"#{@resource.title.first}\""
    respond_to do |f|
      f.json do
        render json: manifest_builder.build
      end
    end
  end

  # View the structural metadata for a given repository resource
  def structure
    @change_set = ChangeSet.for(find_resource(params[:id])).prepopulate!
    authorize! :structure, @change_set.resource
    @logical_order = (Array(@change_set.logical_structure).first || Structure.new).decorate
    members = Wayfinder.for(@change_set.resource).members_with_parents
    @logical_order = WithProxyForObject.new(@logical_order, members)
  end

  # Legacy Structure Manager will temporarily stay in Figgy
  def struct_manager
    @change_set = ChangeSet.for(find_resource(params[:id])).prepopulate!
    authorize! :structure, @change_set.resource
    @logical_order = (Array(@change_set.logical_structure).first || Structure.new).decorate
    members = Wayfinder.for(@change_set.resource).members_with_parents
    @logical_order = WithProxyForObject.new(@logical_order, members)
  end

  def around_delete_action
    # Only allow deleting empty playlists. Avoids difficulty of restoring a
    # full playlist from preservation and supporting restoring accidentally
    # deleted playlists.
    if @change_set.resource.is_a?(Playlist) && @change_set.resource.member_ids.count.positive?
      flash[:alert] = "Unable to delete a playlist with tracks."
      redirect_to solr_document_path(@change_set.resource.id.to_s)
    else
      yield
    end
  end

  private

    def manifest_builder
      ManifestBuilder.new(@resource, params[:auth_token])
    end
end
