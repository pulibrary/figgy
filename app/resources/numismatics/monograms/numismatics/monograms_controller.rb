# frozen_string_literal: true

module Numismatics
  class MonogramsController < ResourceController
    self.resource_class = Numismatics::Monogram
    self.change_set_persister = ::ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie.config.storage_adapter
    )
    before_action :load_numismatic_monograms, only: :index

    def index
      render "index"
    end

    def after_create_success(_obj, _change_set)
      redirect_to numismatics_monograms_path
    end

    def after_update_success(_obj, _change_set)
      redirect_to numismatics_monograms_path
    end

    def manifest
      @resource = find_resource(params[:id])
      authorize! :manifest, @resource
      respond_to do |f|
        f.json do
          render json: ManifestBuilder.new(@resource).build
        end
      end
    rescue Valkyrie::Persistence::ObjectNotFoundError
      render json: {message: "No manifest found for #{params[:id]}"}
    end

    private

      def load_numismatic_monograms
        @numismatic_monograms = query_service.find_all_of_model(model: Numismatics::Monogram).map(&:decorate)
        return [] if @numismatic_monograms.to_a.blank?
      end
  end
end
