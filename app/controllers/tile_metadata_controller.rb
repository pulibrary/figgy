# frozen_string_literal: true
class TileMetadataController < ApplicationController
  attr_reader :resource

  def metadata
    @resource = find_resource(params[:id])
    if resource.is_a?(RasterResource) && resource.decorate.raster_set?
      respond_to do |f|
        f.json do
          render json: { uri: cached_mosaic_path }
        end
      end
    else
      respond_to do |f|
        f.json { head :not_found }
      end
    end
  end

  private

    def cached_mosaic_path
      # Cache expires after 10 minutes. Race condition TTL set to 60 seconds - if
      # the fingerprinted mosaic is not found in S3, then it is generated on the
      # fly which can take some time. This multiple calls to the endpoint from
      # generating the document at the same time.
      Rails.cache.fetch("mosaic-manifest-#{resource.id}", expires_in: 600, race_condition_ttl: 60) do
        MosaicService.new(resource: resource).path
      end
    end
end