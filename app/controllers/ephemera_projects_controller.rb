# frozen_string_literal: true
class EphemeraProjectsController < ResourcesController
  self.resource_class = EphemeraProject
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
  before_action :load_ephemera_projects, only: :index

  def index
    render "index"
  end

  def folders
    render json: JSON.dump(data: datatables_folders.to_a)
  end

  def datatables_folders
    FolderDataSource.new(resource: resource.decorate, helper: helper).data
  end

  def manifest
    @resource = find_resource(params[:id])
    respond_to do |f|
      f.json do
        render json: ManifestBuilder.new(@resource).build
      end
    end
  end

  def around_delete_action
    # Only allow deleting empty projects. Avoids difficulty of restoring a
    # full project from preservation and supporting restoring accidentally
    # deleted projects.
    if @change_set.resource.member_ids.present?
      flash[:alert] = "Unable to delete a project with members."
      redirect_to solr_document_path(@change_set.resource.id.to_s)
    else
      yield
    end
  end

  private

    def helper
      EphemeraProjectDecorator.new(nil).h
    end

    def load_ephemera_projects
      @ephemera_projects = query_service.find_all_of_model(model: EphemeraProject).map(&:decorate)
    end
end
