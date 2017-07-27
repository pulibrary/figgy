# frozen_string_literal: true
class RemoteRecord
  def self.retrieve(source_metadata_identifier)
    if PulMetadataServices::Client.bibdata?(source_metadata_identifier)
      new(source_metadata_identifier)
    else
      PulfaRecord.new(source_metadata_identifier)
    end
  end

  class PulfaRecord
    attr_reader :source_metadata_identifier
    def initialize(source_metadata_identifier)
      @source_metadata_identifier = source_metadata_identifier
    end

    delegate :attributes, to: :client_result

    def success?
      client_result.source.strip.present?
    end

    def client_result
      @client_result ||= PulMetadataServices::Client.retrieve(source_metadata_identifier)
    end
  end

  attr_reader :source_metadata_identifier
  delegate :success?, to: :jsonld_request
  def initialize(source_metadata_identifier)
    @source_metadata_identifier = source_metadata_identifier
  end

  def attributes
    JSONLDBuilder.for(jsonld).result
  end

  private

    def jsonld_request
      @jsonld_request ||= Faraday.get("https://bibdata.princeton.edu/bibliographic/#{source_metadata_identifier}/jsonld")
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
