# frozen_string_literal: true
class PlaylistsController < BaseResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = Playlist
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )

  def resource_params
    return super unless params[:media_reserve_id]
    {
      label: "Playlist: #{media_reserve.title.first}",
      file_set_ids: media_reserve.member_ids
    }
  end

  def media_reserve
    @media_reserve ||= query_service.find_by(id: params[:media_reserve_id])
  end
end
