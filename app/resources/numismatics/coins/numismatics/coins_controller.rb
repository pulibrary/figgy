# frozen_string_literal: true
module Numismatics
  class CoinsController < ResourceController
    include OrangelightDocumentController

    self.resource_class = Numismatics::Coin
    self.change_set_persister = ::ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie.config.storage_adapter
    )

    before_action :load_facet_values, only: [:new, :edit, :update]
    before_action :load_numismatic_collections, only: [:new, :edit, :update]
    before_action :selected_issue, only: [:new, :edit, :destroy, :update]

    def facet_fields
      [
        :numismatic_collection_ssim
      ]
    end

    def after_delete_success
      flash[:alert] = "Numismatics::Coin was deleted successfully"
      redirect_to solr_document_path(@selected_issue)
    end

    def auth_token_param
      params[:auth_token]
    end

    def auto_ingest
      authorize! :create, resource_class
      IngestFolderJob.perform_later(directory: file_locator.folder_pathname.to_s, property: "id", id: resource.id.to_s)
      redirect_to file_manager_numismatics_coin_path(params[:id])
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

    def load_facet_values
      query = FindFacetValues.new(query_service: Valkyrie::MetadataAdapter.find(:index_solr).query_service)
      @facet_values = query.find_facet_values(facet_fields: facet_fields)
    end

    def load_numismatic_collections
      @numismatic_collections = @facet_values[:numismatic_collection_ssim]
    end

    def numismatic_issue
      parent_resource.is_a?(Numismatics::Issue) ? parent_resource : nil
    end

    def manifest
      authorize! :manifest, resource
      respond_to do |f|
        f.json do
          render json: ManifestBuilder.new(resource).build
        end
      end
    end

    def parent_resource
      @parent_resource ||=
        if params[:id]
          find_resource(params[:id]).decorate.parent
        elsif params[:parent_id]
          find_resource(params[:parent_id])
        end
    end

    def pdf
      change_set = ChangeSet.for(find_resource(params[:id]))
      authorize! :pdf, change_set.resource
      pdf_file = PDFService.new(change_set_persister).find_or_generate(change_set)

      redirect_path_args = { resource_id: change_set.id, id: pdf_file.id }
      redirect_path_args[:auth_token] = auth_token_param if auth_token_param
      redirect_to download_path(redirect_path_args)
    end

    def selected_issue
      @selected_issue = numismatic_issue&.id.to_s
    end

    def storage_adapter
      Valkyrie.config.storage_adapter
    end

    def after_create_success(obj, _change_set)
      if params[:commit] == "Save and Duplicate Metadata"
        redirect_to new_numismatics_coin_path(parent_id: resource_params[:append_id], create_another: obj.id.to_s), notice: "Coin #{obj.coin_number} Saved, Creating Another..."
      else
        super
      end
    end

    def after_update_success(obj, _change_set)
      if params[:commit] == "Save and Duplicate Metadata"
        # This is normally passed using append_id
        parent_id = obj.decorate.parent&.id
        redirect_to new_numismatics_coin_path(parent_id: parent_id, create_another: obj.id.to_s), notice: "Coin #{obj.coin_number} Saved, Creating Another..."
      else
        super
      end
    end

    def new_resource
      if params[:create_another]
        resource = find_resource(params[:create_another])
        # Setting new_record to true ensures that this is not treated as a persisted Resource
        # @see Valkyrie::Resource#persisted?
        # @see https://github.com/samvera-labs/valkyrie/blob/master/lib/valkyrie/resource.rb#L83
        resource.new(id: nil, new_record: true, created_at: nil, updated_at: nil)
      else
        resource_class.new
      end
    end

    private

      def file_locator
        IngestFolderLocator.new(id: resource.coin_number, search_directory: "numismatics")
      end
  end
end
