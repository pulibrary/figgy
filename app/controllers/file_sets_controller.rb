# frozen_string_literal: true
class FileSetsController < ApplicationController
  include Valhalla::ResourceController
  include TokenAuth
  self.change_set_class = DynamicChangeSet
  self.resource_class = FileSet
  self.change_set_persister = ::PlumChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie::StorageAdapter.find(:disk)
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

  def derivative_change_set_persister
    ::PlumChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:derivatives)
    )
  end

  def update
    @change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
    authorize! :update, @change_set.resource
    render :edit unless @change_set.validate(resource_params)
    @change_set.sync
    obj = nil
    change_set_persister.buffer_into_index do |persist|
      obj = persist.save(change_set: @change_set)
    end

    update_derivatives if derivative_resource_params

    respond_to do |format|
      format.html do
        redirect_to contextual_path(obj, @change_set).show
      end
      format.json { head :ok }
    end
  end

  private

    def filtered_file_params(filter:)
      filtered = params[resource_class.to_s.underscore.to_sym]
      filtered['files'] = filtered.fetch(filter, [])
      filtered.delete(filter)
      filtered.to_unsafe_h
    end

    def derivative_resource_params
      @derivative_resource_params ||= filtered_file_params(filter: 'derivative_files')
    end

    def update_derivatives
      return unless @change_set.validate(derivative_resource_params)
      @change_set.sync
      derivative_change_set_persister.buffer_into_index do |persist|
        persist.save(change_set: @change_set)
      end
    end
end
