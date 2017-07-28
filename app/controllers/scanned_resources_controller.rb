# frozen_string_literal: true
class ScannedResourcesController < ApplicationController
  include Valhalla::ResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = ScannedResource
  self.change_set_persister = PlumChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )

  def browse_everything_files
    resource = find_resource(params[:id])
    BrowseEverythingIngestJob.perform_later(resource.id.to_s, self.class.to_s, params[:selected_files].to_unsafe_h)
    redirect_to Valhalla::ContextualPath.new(child: resource, parent_id: nil).file_manager
  end
end
