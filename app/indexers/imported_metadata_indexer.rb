# frozen_string_literal: true
class ImportedMetadataIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.try(:primary_imported_metadata)
    {
      local_identifier_ssim: imported_or_existing(attribute: :local_identifier)
    }
  end

  def imported_or_existing(attribute:)
    resource.primary_imported_metadata.send(attribute) ? resource.primary_imported_metadata.send(attribute) : resource.try(attribute)
  end
end
