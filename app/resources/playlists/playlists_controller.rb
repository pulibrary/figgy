# frozen_string_literal: true
class PlaylistsController < BaseResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = Playlist
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )

  def resource_params
    values = super
    if !values.nil? && values[:file_set_ids]
      file_set_ids = values[:file_set_ids]
      values[:file_set_ids] = file_set_ids.uniq
    end

    return values unless params[:recording_id]
    {
      title: "Playlist: #{recording.title.first}",
      file_set_ids: recording.member_ids
    }
  end

  def recording
    @recording ||= query_service.find_by(id: params[:recording_id])
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
    render json: { message: "No manifest found for #{params[:id]}" }
  end
end
