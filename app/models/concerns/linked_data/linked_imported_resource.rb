# frozen_string_literal: true
module LinkedData
  class LinkedImportedResource < LinkedResource
    def as_jsonld
      record_link.merge(imported_jsonld).merge(super).stringify_keys
    end

    private

      def imported_jsonld
        return {} unless resource.respond_to?(:primary_imported_metadata)
        return finding_aid_metadata if resource.source_metadata_identifier.present? && RemoteRecord.pulfa?(resource.source_metadata_identifier.first)
        return {} unless resource.primary_imported_metadata.source_jsonld.present?
        @imported_jsonld ||= JSON.parse(resource.primary_imported_metadata.source_jsonld.first)
      end

      def finding_aid_metadata
        resource.decorate.iiif_manifest_attributes.select { |_k, v| v.present? }
      end

      def record_link
        return {} unless resource.source_metadata_identifier
        { record_link_heading => RemoteRecord.record_url(resource.source_metadata_identifier.first) }
      end

      def record_link_heading
        if PulMetadataServices::Client.bibdata?(resource.source_metadata_identifier.first)
          :link_to_catalog
        else
          :link_to_finding_aid
        end
      end
  end
end
