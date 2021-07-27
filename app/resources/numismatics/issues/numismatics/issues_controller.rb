# frozen_string_literal: true
module Numismatics
  class IssuesController < BaseResourceController
    self.resource_class = Numismatics::Issue
    self.change_set_persister = ::ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie.config.storage_adapter
    )

    before_action :load_facet_values, only: [:new, :edit, :update]
    before_action :load_colors, only: [:new, :edit, :update]
    before_action :load_denominations, only: [:new, :edit, :update]
    before_action :load_edges, only: [:new, :edit, :update]
    before_action :load_metals, only: [:new, :edit, :update]
    before_action :load_monograms, only: [:new, :edit, :update]
    before_action :load_monogram_attributes, only: [:new, :edit, :update]
    before_action :load_object_types, only: [:new, :edit, :update]
    before_action :load_obverse_figures, only: [:new, :edit, :update]
    before_action :load_obverse_orientations, only: [:new, :edit, :update]
    before_action :load_obverse_parts, only: [:new, :edit, :update]
    before_action :load_reverse_figures, only: [:new, :edit, :update]
    before_action :load_reverse_orientations, only: [:new, :edit, :update]
    before_action :load_reverse_parts, only: [:new, :edit, :update]
    before_action :load_shapes, only: [:new, :edit, :update]

    def facet_fields
      [
        :color_ssim,
        :denomination_ssim,
        :edge_ssim,
        :metal_ssim,
        :object_type_ssim,
        :obverse_figure_ssim,
        :obverse_orientation_ssim,
        :obverse_part_ssim,
        :reverse_figure_ssim,
        :reverse_orientation_ssim,
        :reverse_part_ssim,
        :shape_ssim
      ]
    end

    def load_colors
      @colors = @facet_values[:color_ssim]
    end

    def load_denominations
      @denominations = @facet_values[:denomination_ssim]
    end

    def load_edges
      @edges = @facet_values[:edge_ssim]
    end

    def load_facet_values
      query = FindFacetValues.new(query_service: Valkyrie::MetadataAdapter.find(:index_solr).query_service)
      @facet_values = query.find_facet_values(facet_fields: facet_fields)
    end

    def load_metals
      @metals = @facet_values[:metal_ssim]
    end

    def load_monograms
      @numismatic_monograms = query_service.find_all_of_model(model: Numismatics::Monogram).map(&:decorate)

      return [] if @numismatic_monograms.to_a.blank?
    end

    def load_object_types
      @object_types = @facet_values[:object_type_ssim]
    end

    def load_obverse_figures
      @obverse_figures = @facet_values[:obverse_figure_ssim]
    end

    def load_obverse_orientations
      @obverse_orientations = @facet_values[:obverse_orientation_ssim]
    end

    def load_obverse_parts
      @obverse_parts = @facet_values[:obverse_part_ssim]
    end

    def load_reverse_figures
      @reverse_figures = @facet_values[:reverse_figure_ssim]
    end

    def load_reverse_orientations
      @reverse_orientations = @facet_values[:reverse_orientation_ssim]
    end

    def load_reverse_parts
      @reverse_parts = @facet_values[:reverse_part_ssim]
    end

    def load_shapes
      @shapes = @facet_values[:shape_ssim]
    end

    def manifest
      authorize! :manifest, resource
      respond_to do |f|
        f.json do
          render json: ManifestBuilder.new(resource).build
        end
      end
    end

    def after_create_success(obj, _change_set)
      if params[:commit] == "Save and Duplicate Metadata"
        redirect_to new_numismatics_issue_path(parent_id: resource_params[:append_id], create_another: obj.id.to_s), notice: "Issue #{obj.issue_number} Saved, Creating Another..."
      else
        super
      end
    end

    def after_update_success(obj, _change_set)
      if params[:commit] == "Save and Duplicate Metadata"
        redirect_to new_numismatics_issue_path(parent_id: resource_params[:append_id], create_another: obj.id.to_s), notice: "Issue #{obj.issue_number} Saved, Creating Another..."
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
