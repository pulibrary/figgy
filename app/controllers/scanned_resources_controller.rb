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
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      change_set.validate(pending_uploads: change_set.pending_uploads + selected_files)
      change_set.sync
      buffered_changeset_persister.save(change_set: change_set)
    end
    BrowseEverythingIngestJob.perform_later(resource.id.to_s, self.class.to_s, selected_files.map(&:id).map(&:to_s))
    redirect_to Valhalla::ContextualPath.new(child: resource, parent_id: nil).file_manager
  end

  def selected_file_params
    params[:selected_files].to_unsafe_h
  end

  def selected_files
    @selected_files ||= selected_file_params.values.map do |x|
      PendingUpload.new(x.symbolize_keys.merge(id: SecureRandom.uuid, created_at: Time.current.utc.iso8601))
    end
  end

  def resource
    find_resource(params[:id])
  end

  def change_set
    @change_set ||= change_set_class.new(resource)
  end
end
