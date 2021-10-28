# frozen_string_literal: true
class ManifestsController < ApplicationController
  # Render the V3 IIIF presentation manifest for a given repository resource
  def v3
    @resource = find_resource(params[:id])
    authorize! :manifest, @resource

    if implemented_resource_types.include?(@resource.class)
      respond_to do |f|
        f.json do
          render json: cached_manifest(@resource, auth_token_param)
        end
      end
    else
      head :not_implemented
    end

  rescue Valkyrie::Persistence::ObjectNotFoundError
    find_by_local_identifier
  end

  private

    def auth_token_param
      params[:auth_token]
    end

    def cached_manifest(resource, auth_token_param)
      Rails.cache.fetch("#{ManifestKey.for(resource)}/v3/#{auth_token_param}") do
        ManifestBuilderV3.new(resource, auth_token_param).build.to_json
      end
    end

    def find_by_local_identifier
      @resource = query_service.custom_queries.find_by_local_identifier(local_identifier: params[:resource_id]).first
      raise Valkyrie::Persistence::ObjectNotFoundError unless @resource
      redirect_to manifest_v3_path(id: @resource.id.to_s)
    end

    def implemented_resource_types
      [ScannedMap]
    end
end
