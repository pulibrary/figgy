# frozen_string_literal: true

class NomismaDocumentsController < ApplicationController
  before_action :set_nomisma_documents, only: [:index, :void]
  before_action :set_single_nomisma_document, only: [:destroy, :download]

  def index; end

  def destroy
    authorize! :destroy, @nomisma_document
    @nomisma_document.destroy
    respond_to do |format|
      format.html { redirect_to nomisma_documents_url, notice: "Nomisma document was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def download
    respond_to do |format|
      format.rdf { send_data(@nomisma_document.rdf, type: "application/xml", disposition: :inline) }
    end
  rescue ActionController::UnknownFormat
    head :not_implemented
  end

  def void
    respond_to do |format|
      format.rdf { send_data(void_document, type: "application/xml", disposition: :inline) }
    end
  rescue ActionController::UnknownFormat
    head :not_implemented
  end

  private

    def set_nomisma_documents
      @nomisma_documents = NomismaDocument.where("created_at > ?", 3.months.ago).order(created_at: :desc)
      @most_recent = @nomisma_documents.find { |d| d.state == "complete" }
    end

    def set_single_nomisma_document
      @nomisma_document = NomismaDocument.find(params[:id])
    end

    def void_document
      download_url = url_helpers.full_url_for(@most_recent) + "/princeton-nomisma.rdf"
      Nomisma::Void.generate(url: download_url, date: @most_recent.created_at)
    end

    def url_helpers
      Rails.application.routes.url_helpers
    end
end
