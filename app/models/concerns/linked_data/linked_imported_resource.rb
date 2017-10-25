# frozen_string_literal: true
module LinkedData
  class LinkedImportedResource < LinkedResource
    def as_jsonld
      imported_jsonld.merge(super).stringify_keys
    end

    private

      def imported_jsonld
        return {} unless resource.respond_to?(:primary_imported_metadata) && resource.primary_imported_metadata.source_jsonld.present?
        @imported_jsonld ||= JSON.parse(resource.primary_imported_metadata.source_jsonld.first)
      end
  end
end
