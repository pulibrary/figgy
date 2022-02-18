# frozen_string_literal: true

class UniqueArchivalMediaComponentIdValidator < ActiveModel::Validator
  def validate(record)
    duplicates = find_duplicates(record)
    return if duplicates.count.zero?
    record.errors.add(:source_metadata_identifier,
      "Value already in use on another Archival Media Collection. Ingest to #{link_to_duplicate(duplicates.first)}?".html_safe)
  end

  private

    def find_duplicates(record)
      query_service.custom_queries.find_by_property(
        property: :source_metadata_identifier,
        value: record.source_metadata_identifier
      ).select do |resource|
        resource.is_a?(Collection) && resource.id != record.id
      end
    end

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end

    def link_to_duplicate(resource)
      "<a href=\"#{Rails.application.routes.url_helpers.edit_collection_path(resource)}\">#{resource.title.first}</a>"
    end
end
