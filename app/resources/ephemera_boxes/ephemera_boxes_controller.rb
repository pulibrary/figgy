# frozen_string_literal: true
class EphemeraBoxesController < BaseResourceController
  self.resource_class = EphemeraBox
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )

  before_action :load_collections, only: [:new, :edit]
  before_action :cache_project, only: :destroy

  def folders
    authorize! :read, resource
    render json: { data: datatables_folders }
  end

  def datatables_folders
    FolderDataSource.new(resource: resource.decorate, helper: helper).data
  end

  def attach_drive
    edit
  end

  def cache_project
    @ephemera_project = find_resource(params[:id]).decorate.ephemera_project
  end

  def after_delete_success
    redirect_to solr_document_path(id: @ephemera_project.id)
  end

  private

    def helper
      EphemeraBoxDecorator.new(nil).h
    end

    def load_collections
      @collections = query_service.find_all_of_model(model: Collection).map(&:decorate)
    end
end
