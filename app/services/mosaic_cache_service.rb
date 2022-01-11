# frozen_string_literal: true

class MosaicCacheService
  class Error < StandardError; end
  attr_reader :resource
  # @param resource [RasterResource]
  attr_reader :mosaic_only
  def initialize(resource:, mosaic_only: true)
    @resource = resource.decorate
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
        caller_reference: resource.id.to_s
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
      if mosaic_only
        "/resources/#{resource.id}"
      else
        "*#{resource.id}*"
      end
    end
end
