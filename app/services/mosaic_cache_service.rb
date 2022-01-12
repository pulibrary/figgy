# frozen_string_literal: true

class MosaicCacheService
  class Error < StandardError; end
  attr_reader :resource
  # @param resource [RasterResource]
  attr_reader :resource_id, :mosaic_only
  def initialize(resource_id:, mosaic_only: true)
    @resource_id = resource_id
    @mosaic_only = mosaic_only
  end

  def invalidate
    return unless distribution
    client.create_invalidation(
      distribution_id: distribution.id,
      invalidation_batch: {
        paths: {
          quantity: 1,
          items: [path]
        },
        caller_reference: resource_id
      }
    )
  end

  private

    def client
      @client ||= Aws::CloudFront::Client.new(
        region: Figgy.config["cloud_geo_region"],
        access_key_id: Figgy.config["aws_access_key_id"],
        secret_access_key: Figgy.config["aws_secret_access_key"]
      )
    end

    def items
      client.list_distributions.distribution_list.items
    end

    def distribution
      @distribution ||= begin
        items.find do |item|
          item&.aliases&.items&.first == Figgy.config["tileserver"][:url]
        end
      end
    end

    def path
      id = resource_id.delete("-")
      if mosaic_only
        "/resources/#{id}"
      else
        "*#{id}*"
      end
    end
end
