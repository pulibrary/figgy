# frozen_string_literal: true
class EphemeraProjectsController < ApplicationController
  include Valhalla::ResourceController
  include TokenAuth
  self.change_set_class = DynamicChangeSet
  self.resource_class = EphemeraProject
  self.change_set_persister = ::PlumChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
  before_action :load_collections, only: [:new, :edit]
  before_action :load_ephemera_projects, only: :index
  before_action :load_templates, only: :show
  before_action :set_ephemera_project, only: :show

  def change_set
    @change_set ||= change_set_class.new(resource)
  end

  def index
    render 'index'
  end

  private

    def load_collections
      @collections = query_service.find_all_of_model(model: Collection).map(&:decorate)
    end

    def load_ephemera_projects
      @ephemera_projects = query_service.find_all_of_model(model: EphemeraProject).map(&:decorate)
    end

    def load_templates
      @templates = []
    end

    def set_ephemera_project
      @ephemera_project = query_service.find_by(id: Valkyrie::ID.new(params[:id]))
    end
end
