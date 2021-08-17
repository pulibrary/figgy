# frozen_string_literal: true
class RemoteRecord
  # Factory method for PulMetadataServices objects
  # @param source_metadata_identifier [String]
  # @param resource [Resource]
  # @return [RemoteRecord, RemoteRecord::PulfaRecord]
  def self.retrieve(source_metadata_identifier, resource: nil)
    if bibdata?(source_metadata_identifier)
      new(source_metadata_identifier)
    elsif pulfa?(source_metadata_identifier)
      PulfaRecord.new(source_metadata_identifier, resource)
    end
  end

  def self.bibdata?(source_metadata_identifier)
    PulMetadataServices::Client.bibdata?(source_metadata_identifier)
  end

  def self.pulfa?(source_metadata_identifier)
    return false if source_metadata_identifier.match?(/\//)
    source_metadata_identifier.match?(/^(aspace_)?([A-Z][a-zA-Z0-9\.-]+)(_[a-z0-9]+)?/)
  end

  def self.pulfa_collection(source_metadata_identifier)
    return if source_metadata_identifier.match?(/\//)
    m = source_metadata_identifier.match(/^(aspace_)?(?<code>[A-Z][a-zA-Z0-9.-]+)([_][a-z0-9]+)?/)
    m[:code] if m
  end

  def self.pulfa_component(source_metadata_identifier)
    return if source_metadata_identifier.match?(/\//)
    return unless source_metadata_identifier.match?(/_/)
    m = source_metadata_identifier.match(/^[A-Z][a-zA-Z0-9.-]+_([a-z0-9]+)/)
    m[1] if m
  end

  def self.valid?(source_metadata_identifier)
    bibdata?(source_metadata_identifier) || pulfa?(source_metadata_identifier)
  end

  def self.source_metadata_url(id)
    return "#{Figgy.config[:bibdata_url]}#{id}" if bibdata?(id)
    "#{Figgy.config[:legacy_findingaids_url]}#{id.tr('_', '/')}.xml?scope=record" if pulfa?(id)
  end

  def self.record_url(id)
    return unless id
    return "https://catalog.princeton.edu/catalog/#{id}" if bibdata?(id)
    "#{Figgy.config[:legacy_findingaids_url]}#{id.tr('_', '/')}" if pulfa?(id)
  end

  class PulfaRecord
    attr_reader :source_metadata_identifier

    # Constructor
    # @param source_metadata_identifier [String]
    # @param resource [Resource]
    def initialize(source_metadata_identifier, resource = nil)
      @source_metadata_identifier = source_metadata_identifier
      @resource = resource
    end

    def attributes
      @attributes ||= client_result.attributes.merge(source_metadata: client_result.full_source)
    end

    def success?
      client_result.source.strip.present?
    end

    def client_result
      @client_result ||= PulMetadataServices::Client.retrieve(source_metadata_identifier, @resource)
    end
  end

  attr_reader :source_metadata_identifier
  delegate :success?, to: :jsonld_request
  def initialize(source_metadata_identifier)
    @source_metadata_identifier = source_metadata_identifier
  end

  def attributes
    hash = JSONLDBuilder.for(jsonld).result
    hash[:content_type] = hash[:format] # we can't use format because it's a rails reserved word
    hash.merge(source_jsonld: jsonld.to_json)
  end

  private

    def jsonld_request
      @jsonld_request ||=
        begin
          request = Faraday.get("#{Figgy.config[:bibdata_url]}#{source_metadata_identifier}/jsonld")
          if request.status.to_s == "404"
            request = Faraday.get("#{Figgy.config[:bibdata_url]}99#{source_metadata_identifier}3506421/jsonld")
          end
          request
        end
    end

    def jsonld
      @jsonld ||= MultiJson.load(jsonld_request.body, symbolize_keys: true)
    end

    class JSONLDBuilder < ::Valkyrie::ValueMapper
    end

    class TypedLiteral < ::Valkyrie::ValueMapper
      JSONLDBuilder.register(self)
      def self.handles?(value)
        value.is_a?(Hash) && value[:@value] && value[:@language]
      end

      def result
        RDF::Literal.new(value[:@value], language: value[:@language])
      end
    end

    class LabeledURIBuilder < ::Valkyrie::ValueMapper
      JSONLDBuilder.register(self)
      def self.handles?(value)
        value.is_a?(Hash) && value[:label] && value[:@id]
      end

      def result
        ::LabeledURI.new(
          uri: value[:@id],
          label: value[:label]
        )
      end
    end

    class HashValue < ::Valkyrie::ValueMapper
      JSONLDBuilder.register(self)
      def self.handles?(value)
        value.is_a?(Hash)
      end

      def result
        Hash[value.map do |key, value|
          [key, calling_mapper.for(value).result]
        end]
      end
    end

    class EnumerableNestedValue < ::Valkyrie::ValueMapper
      JSONLDBuilder.register(self)
      def self.handles?(value)
        value.is_a?(Array)
      end

      def result
        value.map do |val|
          calling_mapper.for(val).result
        end
      end
    end
end
