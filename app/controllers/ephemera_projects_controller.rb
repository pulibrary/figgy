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
  before_action :load_ephemera_projects, only: :index

  def index
    render 'index'
  end

  private

    def load_ephemera_projects
      @ephemera_projects = query_service.find_all_of_model(model: EphemeraProject).map(&:decorate)
    end
end
