# frozen_string_literal: true
class FileMetadataController < ApplicationController
  delegate :query_service, to: :change_set_persister

  def new
    authorize! :update, file_set_change_set.resource
    @change_set = ChangeSet.for(FileMetadata.new, change_set_param: change_set_param)
  end

  def create
    authorize! :update, file_set_change_set.resource
    @change_set = ChangeSet.for(FileMetadata.new, change_set_param: change_set_param)
    @change_set.validate(resource_params)
    if @change_set.valid?
      ingestable_file = @change_set.to_ingestable_file
      file_set_change_set.files = [ingestable_file]
      change_set_persister.save(change_set: file_set_change_set)
      redirect_to solr_document_path(file_set_change_set.id.to_s)
    else
      render "new"
    end
  end

  def file_set_change_set
    @file_set_change_set ||= ChangeSet.for(query_service.find_by(id: params[:file_set_id]))
  end

  private

    def _prefixes
      @_prefixes ||= super + ["base"]
    end

    def change_set_persister
      ChangeSetPersister.default
    end

    def change_set_param
      params[:change_set] || (resource_params && resource_params[:change_set])
    end

    def resource_params
      @resource_params ||= params[:file_metadata]
    end
end
