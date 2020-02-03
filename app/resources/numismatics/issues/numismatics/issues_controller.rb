# frozen_string_literal: true
module Numismatics
  class IssuesController < BaseResourceController
    self.change_set_class = DynamicChangeSet
    self.resource_class = Numismatics::Issue
    self.change_set_persister = ::ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie.config.storage_adapter
    )

    before_action :load_monograms, only: [:new, :edit]
    before_action :load_monogram_attributes, only: [:new, :edit]

    def load_monograms
      @numismatic_monograms = query_service.find_all_of_model(model: Numismatics::Monogram).map(&:decorate)

      return [] if @numismatic_monograms.to_a.blank?
    end

    def manifest
      authorize! :manifest, resource
      respond_to do |f|
        f.json do
          render json: ManifestBuilder.new(resource).build
        end
      end
    end

    private

      def build_monogram_thumbnail_url(resource)
        file_sets = resource.decorate.decorated_file_sets.reject { |fs| fs.thumbnail_id.nil? }

        if file_sets.empty?
          helpers.asset_url("default.png")
        else
          ManifestBuilder::ManifestHelper.new.manifest_image_thumbnail_path(file_sets.first)
        end
      end

      # Generates the Vue JSON for the Numismatic Monogram membership component
      # @return [Array<Hash>]
      def load_monogram_attributes
        numismatic_monogram_attributes = @numismatic_monograms.map do |monogram|
          member_thumbnail_url = build_monogram_thumbnail_url(monogram)
          member_url = solr_document_path(id: monogram.id)
          member_monogram_ids = params[:id] ? resource.decorate.decorated_numismatic_monograms.map(&:id) : []

          {
            id: monogram.id.to_s,
            url: member_url,
            thumbnail: member_thumbnail_url,
            title: monogram.decorate.first_title,
            attached: member_monogram_ids.include?(monogram.id)
          }
        end

        @numismatic_monogram_attributes = numismatic_monogram_attributes.sort do |u, v|
          if u[:attached] <=> v[:attached]
            0
          else
            v[:attached] && !u[:attached] ? 1 : -1
          end
        end
      end
  end
end
