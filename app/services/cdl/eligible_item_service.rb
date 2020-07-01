# frozen_string_literal: true

module Cdl
  class EligibleItemService
    # EligibleItemService will return from Voyager items eligible for Controlled Digital Lending (Cdl)
    # on_cdl == "Y"
    class << self
      def item_ids(source_metadata_identifier:)
        conn = Faraday.new(url: "https://bibdata.princeton.edu/")
        response = conn.get("#{source_metadata_identifier}/items")
        items = JSON.parse(response.body).values.map { |l| l[0]["items"] }.compact
        items.select { |i| i[0]["on_cdl"] == "Y" }.map { |i| i[0]["id"] }
      end
    end
  end
end
