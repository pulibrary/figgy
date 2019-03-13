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
    add_024
    add_510
    add_856_ark
    add_856_manifest
    marc
  end

  private

    def add_856_ark
      return unless resource.try(:identifier)&.present?
      ark = Ark.new(resource.identifier.first).uri
      marc.append(MARC::DataField.new("856", "4", "1", MARC::Subfield.new("u", ark))) unless existing_856(ark)
    end

    def add_856_manifest
      return unless resource.try(:identifier)&.present?
      manifest = Rails.application.routes.url_helpers.polymorphic_url([:manifest, resource])
      manifest856 = existing_856(manifest)
      unless manifest856
        manifest856 = MARC::DataField.new("856", "4", "1", MARC::Subfield.new("u", manifest))
        marc.append(manifest856)
      end

      manifest856_q = manifest856.subfields.select { |s| s.code == "q" }.first
      manifest856.append(MARC::Subfield.new("q", "JSON (IIIF Manifest)")) unless manifest856_q
    end

    def add_024
      return unless resource.try(:local_identifier)&.present?
      dcl = resource.local_identifier.first
      dcl024 = existing_024s(dcl).first
      if dcl024
        dcl024.indicator1 = "8"
      else
        dcl024 = MARC::DataField.new("024", "8", " ", MARC::Subfield.new("a", dcl))
        marc.append(dcl024)
      end
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

    def existing_856s
      @existing_856s ||= marc.fields("856").select { |f| f.indicator1.eql?("4") && f.indicator2.eql?("1") }
    end

    def existing_856(uri)
      existing_856s.select do |f|
        f.subfields.select { |s| s.code == "u" }.first.value == uri
      end.first
    end

    def existing_024s(id)
      marc.fields("024").select do |f|
        f.subfields.select { |s| s.code == "a" }.first.value == id
      end
    end

    def references
      marc.fields("510")
          .select { |field| field.subfields.select { |subfield| subfield.code == "a" }.first.value =~ /Cicognara/ }
          .flat_map { |field| field.subfields.select { |subfield| subfield.code == "c" } }
          .map(&:value)
    end
end
