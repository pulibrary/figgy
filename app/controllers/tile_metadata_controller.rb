# frozen_string_literal: true
class TileMetadataController < ApplicationController
  attr_reader :resource

  # If the mosaic service finds no raster file sets, it will raise
  # a MosaicService::Error exception. This ensures we don't run an expensive
  # query multiple times. Rescue the exception and return a 404 rather
  # than a 500 server error. An example of when this might happen is when
  # you pass the id for a MapSet that has no RasterResource grandchildren.
  rescue_from MosaicService::Error, with: :not_found

  def metadata
    @resource = find_resource(params[:id])
    if resource.is_a?(RasterResource) || resource.is_a?(ScannedMap)
      respond_to do |f|
        f.json do
          render json: { uri: cached_mosaic_path }
        end
      end
    else
      not_found
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

    def not_found
      respond_to do |format|
        format.json { head :not_found }
      end
    end
end
