# frozen_string_literal: true

class AddMmsIdByTitleJob < AddMmsIdByArkJob
  # queue_as :realtime
  queue_as :high

  class FindMmsIdByTitleError < StandardError; end

  def error_klass
    FindMmsIdByTitleError
  end

  private

    def query_filters
      [
        "Serials and series reports (Publicly Accessible) - ",
        "Serials and series reports (Access Limited to Princeton) - "
      ]
    end

    def query
      filtered = resource.title
      query_filters.each do |filter|
        filtered = filtered.map { |title| title.gsub(filter, "") }
      end
      filtered.first
    end

    def search_field
      "title"
    end

    def attribute_key
      "electronic_portfolio_s"
    end

    def attribute_value
      "DSpace"
    end

    def find_catalog_record
      matches = find_catalog_records
      matches.first
    end
end
