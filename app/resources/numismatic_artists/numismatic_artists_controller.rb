# frozen_string_literal: true
class NumismaticArtistsController < BaseResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = NumismaticArtist
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )

  def new
    @change_set = change_set_class.new(new_resource, artist_parent_id: params[:parent_id]).prepopulate!
    authorize! :create, resource_class
  end

  def after_create_success(obj, change_set)
    obj = parent_resource if parent_resource
    super
  end

  private

    def parent_resource
      @parent_resource ||= find_resource(@change_set.artist_parent_id)
    end
end
