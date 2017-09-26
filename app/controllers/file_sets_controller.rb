# frozen_string_literal: true
class FileSetsController < ApplicationController
  include Valhalla::ResourceController
  include TokenAuth
  self.change_set_class = DynamicChangeSet
  self.resource_class = FileSet
  self.change_set_persister = ::PlumChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie::StorageAdapter.find(:file_typed_disk)
  )

  def derivatives
    file_set = find_resource(params[:id])
    @change_set = change_set_class.new(file_set).prepopulate!
    authorize! :derive, @change_set.resource
    output = CreateDerivativesJob.perform_later(params[:id])
    respond_to do |format|
      format.json do
        render json: output
      end
      format.html do
        redirect_to polymorphic_path file_set
      end
    end
  end
end
