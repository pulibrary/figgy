# frozen_string_literal: true

class MarcRecordEnhancer
  attr_accessor :marc, :resource
  def initialize(marc:, resource:)
    @marc = marc
    @resource = resource
  end

  # Factory
  # @param [Resource] any resource with source_metadata_identifier
  # @return [MarcRecordEnhancer]
  def self.for(resource)
    return unless resource.try(:source_metadata_identifier)
    bibid = resource.source_metadata_identifier.first
    return unless PulMetadataServices::Client.bibdata? bibid
    xml_str = PulMetadataServices::Client.retrieve_from_bibdata(bibid)
    record = MARC::XMLReader.new(StringIO.new(xml_str), parser: "magic").first
    new(marc: record, resource: resource)
  end

  def enhance_cicognara
    add_856es
    add_024
    add_510
    marc
  end

  private

    def add_856es
      return unless resource.try(:identifier)&.present?
      ark = Ark.new(resource.identifier.first).uri
      manifest = Rails.application.routes.url_helpers.polymorphic_url([:manifest, resource])
      marc.append(MARC::DataField.new("856", "4", "1", MARC::Subfield.new("u", manifest))) unless url_strings.include? manifest
      marc.append(MARC::DataField.new("856", "4", "1", MARC::Subfield.new("u", ark))) unless url_strings.include? ark
    end

    def add_024
      return unless resource.try(:local_identifier)&.present?
      dcl = resource.local_identifier.first
      return if standard_identifiers.include? dcl
      marc.append(
        MARC::DataField.new(
          "024", "7", " ",
          MARC::Subfield.new("a", dcl),
          MARC::Subfield.new("2", "dclib")
        )
      )
    end

    def add_510
      return unless resource.try(:imported_metadata)&.first&.references&.present?
      cico_reference = resource.imported_metadata.first.references.first
      return unless cico_reference =~ /Cicognara/ && cico_reference =~ /(\d+)[\[A-Za-z\]]*$/
      cico_number = cico_reference.match(/(\d+)[\[A-Za-z\]]*$/)[1]
      return if references.include? cico_number
      marc.append(
        MARC::DataField.new(
          "510", "4", " ",
          MARC::Subfield.new("a", "Cicognara,"),
          MARC::Subfield.new("c", cico_number)
        )
      )
    end

    def url_strings
      @url_strings ||= begin
        url_fields = marc.fields("856").select do |field|
          field.indicator1.eql? "4"
          field.indicator2.eql? "1"
        end
        url_fields.flat_map(&:subfields).select { |s| s.code == "u" }.map(&:value)
      end
    end

    def standard_identifiers
      marc.fields("024").map do |field|
        field.subfields.select { |s| s.code == "a" }.map(&:value).first
      end
    end

    def references
      marc.fields("510")
          .select { |field| field.subfields.select { |subfield| subfield.code == "a" }.first.value =~ /Cicognara/ }
          .flat_map { |field| field.subfields.select { |subfield| subfield.code == "c" } }
          .map(&:value)
    end
end
