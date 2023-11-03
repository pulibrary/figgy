# frozen_string_literal: true
class TileMetadataController < ApplicationController
  # If the tile metadata service finds no raster file sets, it will raise
  # a TileMetadataService::Error exception. This ensures we don't run an expensive
  # query multiple times. Rescue the exception and return a 404 rather
  # than a 500 server error. An example of when this might happen is when
  # you pass the id for a MapSet that has no RasterResource grandchildren.
  rescue_from TileMetadataService::Error, with: :not_found

  def tilejson
    tilejson_path = TilePath.new(find_resource(params[:id])).tilejson
    if tilejson_path
      redirect_to tilejson_path
    else
      not_found
    end
  end

  def metadata
    mosaic_path = cached_mosaic_path
    if mosaic_path
      respond_to do |f|
        f.json do
          render json: { uri: mosaic_path }
        end
      end
    else
      not_found
    end
  end

  private

    def cached_mosaic_path
      # Cache expires after 10 minutes. Race condition TTL set to 60 seconds - if
      # the  mosaic is not found in S3, then it is generated on the
      # fly which can take some time. This multiple calls to the endpoint from
      # generating the document at the same time.
      Rails.cache.fetch("mosaic-manifest-#{params[:id]}", expires_in: 600, race_condition_ttl: 60) do
        resource = find_resource(params[:id])
        return nil unless resource.is_a?(RasterResource) || resource.is_a?(ScannedMap)
        Valkyrie::Storage::Disk::BucketedStorage.new(base_path: base_path).generate(resource: resource, original_filename: "mosaic.json", file: nil).to_s
      end
    end

    def not_found
      respond_to do |format|
        format.json { head :not_found }
      end
    end
end
