# frozen_string_literal: true

module Cdl
  class BibdataService
    class << self
      def item_ids(id)
        item_ids = []
        conn = Faraday.new(url: "https://bibdata.princeton.edu/")
        response = conn.get("#{id}/items")
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
