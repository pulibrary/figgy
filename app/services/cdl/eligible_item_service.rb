# frozen_string_literal: true

module CDL
  class EligibleItemService
    class << self
      def item_ids(source_metadata_identifier:)
        # This method controls determining if a resource has CDL items - return
        # an empty array if CDL is disabled.
        return [] unless Figgy.cdl_enabled?
        Rails.cache.fetch("cdl_item_ids_#{source_metadata_identifier}", expires_in: 5.minutes) do
          return [] unless RemoteRecord.catalog?(source_metadata_identifier)
          item_ids = get_item_ids(source_metadata_identifier: source_metadata_identifier)
          # If no matches, try the alma ID version.
          if item_ids.empty?
            get_item_ids(source_metadata_identifier: "99#{source_metadata_identifier}3506421")
          else
            item_ids
          end
        end
      end

      def get_item_ids(source_metadata_identifier:)
        response = Faraday.new(url: bibdata_base).get("bibliographic/#{source_metadata_identifier}/items")
        return [] unless response.success?
        items = JSON.parse(response.body).flat_map do |_location, holdings|
          holdings.flat_map do |holding|
            holding["items"]
          end
        end
        items = items.select do |item|
          item && cdl?(item)
        end
        items.map { |x| x["id"] }
      end

      def bibdata_base
        ENV["BIBDATA_BASE"] || "https://bibdata.princeton.edu/"
      end

      def cdl?(item)
        item["cdl"]
      end
    end
  end
end
