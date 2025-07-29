# frozen_string_literal: true
class ScannedMapsController < ScannedResourcesController
  include GeoResourceController
  include GeoblacklightDocumentController
  before_action :load_thumbnail_members, only: [:edit]

  self.resource_class = ScannedMap

  def load_thumbnail_members
    @thumbnail_members = resource.decorate.thumbnail_members
  end

  # View the structural metadata for a given repository resource
  def struct_manager
    @change_set = ChangeSet.for(find_resource(params[:id])).prepopulate!
    authorize! :structure, @change_set.resource
    @logical_order = (Array(@change_set.logical_structure).first || Structure.new).decorate
    members = Wayfinder.for(@change_set.resource).logical_structure_members
    @logical_order = WithProxyForObject.new(@logical_order, members)
  end

  # Override to force v3 manifests
  def cached_manifest(resource, auth_token_param, _flatten = false)
    Rails.cache.fetch("#{ManifestKey.for(resource)}/#{auth_token_param}") do
      ManifestBuilderV3.new(resource, auth_token_param).build.to_json
    end
  end
end
