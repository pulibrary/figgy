# frozen_string_literal: true
class ScannedMapsController < ScannedResourcesController
  include GeoResourceController
  include GeoblacklightDocumentController
  before_action :load_thumbnail_members, only: [:edit]

  self.resource_class = ScannedMap

  def load_thumbnail_members
    @thumbnail_members = resource.decorate.thumbnail_members
  end

  # Render the IIIF presentation manifest for a given repository resource
  def manifest_v3
    @resource = find_resource(params[:id])
    authorize! :manifest, @resource
    respond_to do |f|
      f.json do
        render json: cached_v3_manifest(@resource, auth_token_param)
      end
    end
  rescue Valkyrie::Persistence::ObjectNotFoundError
    @resource = query_service.custom_queries.find_by_local_identifier(local_identifier: params[:id]).first
    raise Valkyrie::Persistence::ObjectNotFoundError unless @resource
    redirect_to manifest_v3_scanned_map_path(id: @resource.id.to_s)
  end

  def cached_v3_manifest(resource, auth_token_param)
    Rails.cache.fetch("#{ManifestKey.for(resource)}/v3/#{auth_token_param}") do
      ManifestBuilderV3.new(resource, auth_token_param).build.to_json
    end
  end

  # View the structural metadata for a given repository resource
  def structure
    @change_set = ChangeSet.for(find_resource(params[:id])).prepopulate!
    authorize! :structure, @change_set.resource
    @logical_order = (Array(@change_set.logical_structure).first || Structure.new).decorate
    members = Wayfinder.for(@change_set.resource).logical_structure_members
    @logical_order = WithProxyForObject.new(@logical_order, members)
  end
end
