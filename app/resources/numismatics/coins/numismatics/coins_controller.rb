# frozen_string_literal: true
module Numismatics
  class CoinsController < BaseResourceController
    include OrangelightDocumentController

    self.change_set_class = DynamicChangeSet
    self.resource_class = Numismatics::Coin
    self.change_set_persister = ::ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie.config.storage_adapter
    )

    before_action :selected_issue, only: [:new, :edit, :destroy]

    def parent_resource
      @parent_resource ||=
        if params[:id]
          find_resource(params[:id]).decorate.parent
        elsif params[:parent_id]
          find_resource(params[:parent_id])
        end
    end

    def numismatic_issue
      parent_resource.is_a?(Numismatics::Issue) ? parent_resource : nil
    end

    def selected_issue
      @selected_issue = numismatic_issue&.id.to_s
    end

    def manifest
      authorize! :manifest, resource
      respond_to do |f|
        f.json do
          render json: ManifestBuilder.new(resource).build
        end
      end
    end

    # report whether there are files
    def discover_files
      authorize! :create, resource_class
      respond_to do |f|
        f.json do
          render json: file_locator.to_h
        end
      end
    end

    def auto_ingest
      authorize! :create, resource_class
      IngestFolderJob.perform_later(directory: file_locator.folder_pathname.to_s, property: "id", id: resource.id.to_s)
      redirect_to file_manager_numismatics_coin_path(params[:id])
    end

    def pdf
      change_set = change_set_class.new(find_resource(params[:id]))
      authorize! :pdf, change_set.resource
      pdf_file = PDFService.new(change_set_persister).find_or_generate(change_set)

      redirect_path_args = { resource_id: change_set.id, id: pdf_file.id }
      redirect_path_args[:auth_token] = auth_token_param if auth_token_param
      redirect_to download_path(redirect_path_args)
    end

    def storage_adapter
      Valkyrie.config.storage_adapter
    end

    def auth_token_param
      params[:auth_token]
    end

    def after_delete_success
      flash[:alert] = "Numismatics::Coin was deleted successfully"
      redirect_to solr_document_path(@selected_issue)
    end

    private

      def file_locator
        IngestFolderLocator.new(id: resource.coin_number, search_directory: "numismatics")
      end
  end
end
