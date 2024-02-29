# frozen_string_literal: true
class FileMetadataController < ApplicationController
  delegate :query_service, to: :change_set_persister

  def create
    authorize! :update, @file_set
    redirect_to solr_document_path(file_set.id.to_s)
  end

  def file_set
    @file_set ||= query_service.find_by(id: params[:file_set_id])
  end

  private

    def change_set_persister
      ChangeSetPersister.default
    end
end
