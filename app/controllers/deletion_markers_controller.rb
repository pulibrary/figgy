# frozen_string_literal: true
class DeletionMarkersController < ResourcesController
  self.resource_class = DeletionMarker
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )

  def restore
    RestoreFromDeletionMarkerJob.perform_later(params[:id])
    flash[:notice] = "Resource is queued for restoration."
    redirect_to root_url
  end
end
