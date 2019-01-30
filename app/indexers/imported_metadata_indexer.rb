# frozen_string_literal: true
class ImportedMetadataIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.try(:primary_imported_metadata)
    identifier_properties.merge(recording_properties)
  end

  private

    def recording_properties
      return {} unless resource.is_a?(ScannedResource) && resource.change_set == "recording"
      [:author, :composer, :conductor, :lyricist, :singer, :contents].map do |prop|
        ["#{prop}_tesim", imported_or_existing(attribute: prop)]
      end.to_h
    end

    def identifier_properties
      {
        local_identifier_ssim: imported_or_existing(attribute: :local_identifier),
        call_number_tsim: imported_or_existing(attribute: :call_number)
      }
    end

    def imported_or_existing(attribute:)
      resource.primary_imported_metadata.send(attribute) ? resource.primary_imported_metadata.send(attribute) : resource.try(attribute)
    end
end
