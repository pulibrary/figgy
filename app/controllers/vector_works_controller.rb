# frozen_string_literal: true
class VectorWorksController < BaseResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = VectorWork
  self.change_set_persister = ::PlumChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )

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
