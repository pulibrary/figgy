# frozen_string_literal: true
class NumismaticArtistsController < BaseResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = NumismaticArtist
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
  before_action :load_artist_parent, only: :destroy

  def new
    @change_set = change_set_class.new(new_resource, artist_parent_id: params[:parent_id]).prepopulate!
    authorize! :create, resource_class
  end

  def after_create_success(obj, change_set)
    obj = parent_resource if parent_resource
    super
  end

  def after_delete_success
    flash[:alert] = "Artist was deleted successfully"
    redirect_to solr_document_path(@parent)
  end

  private

    def parent_resource
      @parent_resource ||= find_resource(@change_set.artist_parent_id)
    end

    def load_artist_parent
      @parent = Wayfinder.for(resource).numismatic_artist_parent
    end
end
