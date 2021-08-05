# frozen_string_literal: true
class ImportedMetadataIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.imported_metadata&.first.present?
    identifier_properties.merge(primary_imported_properties)
  end

  private

    def identifier_properties
      {
        local_identifier_ssim: imported_or_existing(attribute: :local_identifier),
        call_number_tsim: imported_or_existing(attribute: :call_number),
        container_tesim: imported_or_existing(attribute: :container)
      }
    end

    def imported_or_existing(attribute:)
      return resource[attribute] if resource.imported_metadata.blank?
      resource.imported_metadata.first[attribute] || resource[attribute]
    end

    def primary_imported_properties
      resource.primary_imported_metadata.__attributes__.except(*suppressed_keys).map do |k, v|
        ["imported_#{k}_tesim", format_values(v)]
      end.to_h
    end

    def format_values(value)
      return value.map(&:to_s) if value.is_a?(Array)
      return value.to_s if value
    end

    def suppressed_keys
      [
        :id,
        :internal_resource,
        :created_at,
        :updated_at,
        :new_record,
        :import_url,
        :label,
        :nav_date,
        :ocr_language,
        :pdf_type,
        :relative_path,
        :rendered_rights_statement,
        :rights_statement,
        :source_jsonld,
        :source_metadata,
        :source_metadata_identifier,
        :start_canvas,
        :viewing_direction,
        :viewing_hint,
        :visibility
      ]
    end
end
