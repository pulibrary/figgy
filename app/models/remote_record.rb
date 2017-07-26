# frozen_string_literal: true
class RemoteRecord
  def self.retrieve(source_metadata_identifier)
    new(source_metadata_identifier)
  end

  attr_reader :source_metadata_identifier
  delegate :success?, to: :jsonld_request
  def initialize(source_metadata_identifier)
    @source_metadata_identifier = source_metadata_identifier
  end

  def attributes
    NestedResourceBuilder.for(jsonld).result
  end

  def jsonld_request
    @jsonld_request ||= Faraday.get("https://bibdata.princeton.edu/bibliographic/#{source_metadata_identifier}/jsonld")
  end

  def jsonld
    @jsonld ||= MultiJson.load(jsonld_request.body, symbolize_keys: true)
  end

  class NestedResourceBuilder < ::Valkyrie::ValueMapper
  end

  class NestedURIValue < ::Valkyrie::ValueMapper
    NestedResourceBuilder.register(self)
    def self.handles?(value)
      value.is_a?(Hash) && value[:@id] && !value[:@context]
    end

    def result
      RDF::URI(value[:@id])
    end
  end

  class TypedLiteral < ::Valkyrie::ValueMapper
    NestedResourceBuilder.register(self)
    def self.handles?(value)
      value.is_a?(Hash) && value[:@value] && value[:@language]
    end

    def result
      RDF::Literal.new(value[:@value], language: value[:@language])
    end
  end

  class HashValue < ::Valkyrie::ValueMapper
    NestedResourceBuilder.register(self)
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
    NestedResourceBuilder.register(self)
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
