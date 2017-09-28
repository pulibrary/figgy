# frozen_string_literal: true
class VectorWorksController < ApplicationController
  include Valhalla::ResourceController
  include TokenAuth
  self.change_set_class = DynamicChangeSet
  self.resource_class = VectorWork
  self.change_set_persister = ::PlumChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
  before_action :load_collections, only: [:new, :edit]

  # TODO: possibly DRY this stuff? Shared with scanned_resources_controller
  def load_collections
    @collections = query_service.find_all_of_model(model: Collection).map(&:decorate)
  end

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

  # TODO: below this line is code shared with scanned_maps_controller
  #   DRY?
  def file_manager
    @change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
    authorize! :file_manager, @change_set.resource
    populate_children
  end

  def extract_metadata
    change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
    authorize! :update, change_set.resource
    file_node = query_service.find_by(id: Valkyrie::ID.new(params[:file_set_id]))
    GeoMetadataExtractor.new(change_set: change_set, file_node: file_node, persister: persister).extract
  end

  private

    def populate_children
      @children = decorated_resource.geo_members.map do |x|
        change_set_class.new(x).prepopulate!
      end.to_a

      @metadata_children = decorated_resource.geo_metadata_members.map do |x|
        change_set_class.new(x).prepopulate!
      end.to_a
    end

    def decorated_resource
      @change_set.resource.decorate
    end
end
