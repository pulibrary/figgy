# frozen_string_literal: true
class GeoMetadataExtractor
  attr_reader :change_set, :file_node, :persister
  def initialize(change_set:, file_node:, persister:)
    @change_set = change_set
    @file_node = file_node
    @persister = persister
  end

  def extract
    raise ArgumentError, "MIME type unspecified or not configured" if schema.blank?
    attributes = extractor_class.new(metadata_xml).extract
    apply_metadata(attributes)
    persister.save(change_set: change_set)
  end

  private

    def apply_metadata(attributes)
      attributes.each do |key, value|
        change_set.send("#{key}=".to_sym, value) if change_set.respond_to?(key)
      end
    end

    def extractor_class
      "GeoMetadataExtractor::#{schema.capitalize}".constantize
    end

    def file_object
      @file_object ||= Valkyrie::StorageAdapter.find_by(id: primary_file.file_identifiers[0])
    end

    def metadata_xml
      @metadata_xml ||= Nokogiri::XML(file_object.read)
    end

    def mime_type
      file_node.mime_type.try(:first)
    end

    def primary_file
      file_node.primary_file
    end

    def schema
      ControlledVocabulary::GeoMetadataFormat.new.find(mime_type).try(:label)
    end
end
