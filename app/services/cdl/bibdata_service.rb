# frozen_string_literal: true

module Cdl
  class BibdataService
    class << self
      def item_ids(source_metadata_identifier:)
        item_ids = []
        conn = Faraday.new(url: "https://bibdata.princeton.edu/")
        response = conn.get("#{source_metadata_identifier}/items")
        response.body
        items = JSON.parse(response.body).values.map { |l| l[0]["items"] }
        items.each do |i|
          if i[0]["on_cdl"] == "Y"
            item_ids << i[0]["id"]
          end
        end
        item_ids
      end
    end
  end
end
