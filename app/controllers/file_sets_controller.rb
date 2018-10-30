# frozen_string_literal: true
class FileSetsController < ApplicationController
  include ResourceController
  include TokenAuth
  self.change_set_class = DynamicChangeSet
  self.resource_class = FileSet
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie::StorageAdapter.find(:disk)
  )

  def derivatives
    file_set = find_resource(params[:id])
    @change_set = change_set_class.new(file_set).prepopulate!
    authorize! :derive, @change_set.resource
    output = RegenerateDerivativesJob.perform_later(params[:id])
    respond_to do |format|
      format.json do
        render json: output
      end
      format.html do
        redirect_to polymorphic_path file_set
      end
    end
  end

  def text
    resource = find_resource(params[:id])
    authorize! :read, resource
    render plain: resource.ocr_content.first
  end

  def derivative_change_set_persister
    ::ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:derivatives)
    )
  end

  def update
    @change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
    authorize! :update, @change_set.resource
    if @change_set.validate(resource_params)
      obj = nil
      change_set_persister.buffer_into_index do |persist|
        obj = persist.save(change_set: @change_set)
      end
      update_derivatives unless derivative_resource_params.empty?

      after_update_success(obj, @change_set)
    end
  rescue Valkyrie::Persistence::ObjectNotFoundError => error
    after_update_error error
  end

  # Render the IIIF presentation manifest for a given repository resource
  def manifest
    @resource = find_resource(params[:id])
    authorize! :manifest, @resource
    respond_to do |f|
      f.json do
        render json: ManifestBuilder.new(@resource).build
      end
    end
  rescue Valkyrie::Persistence::ObjectNotFoundError
    @resource = query_service.custom_queries.find_by_local_identifier(local_identifier: params[:id]).first
    raise Valkyrie::Persistence::ObjectNotFoundError unless @resource
    redirect_to manifest_scanned_resource_path(id: @resource.id.to_s)
  end

  private

    def filtered_file_params(file_filter:)
      filtered = resource_params
      files = filtered.fetch(file_filter, [])
      return {} if files.empty?
      filtered["files"] = files
      filtered.delete(file_filter)
      filtered
    end

    def derivative_resource_params
      @derivative_resource_params ||= filtered_file_params(file_filter: "derivative_files")
    end

    def update_derivatives
      return unless @change_set.validate(derivative_resource_params)
      derivative_change_set_persister.buffer_into_index do |persist|
        persist.save(change_set: @change_set)
      end
    end
end
