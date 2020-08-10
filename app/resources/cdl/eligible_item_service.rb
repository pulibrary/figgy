# frozen_string_literal: true

module CDL
  class EligibleItemService
    # EligibleItemService will return from Voyager items eligible for Controlled Digital Lending (Cdl)
    # patron_group_charged == "CDL"
    class << self
      def item_ids(source_metadata_identifier:)
        return [] unless RemoteRecord.bibdata?(source_metadata_identifier)
        response = Faraday.new(url: bibdata_base).get("bibliographic/#{source_metadata_identifier}/items")
        items = JSON.parse(response.body).flat_map do |_location, holdings|
          holdings.flat_map do |holding|
            holding["items"]
          end
        end
        items = items.select do |item|
          item && item["patron_group_charged"] == "CDL"
        end
        items.map { |x| x["id"] }
      end

      def bibdata_base
        "https://bibdata.princeton.edu/"
      end
    end
  end
end
