# frozen_string_literal: true
class RemoteRecord::Catalog
  attr_reader :source_metadata_identifier
  delegate :success?, to: :jsonld_request
  def initialize(source_metadata_identifier)
    @source_metadata_identifier = source_metadata_identifier
  end

  def attributes
    hash = JSONLDBuilder.for(jsonld).result
    hash[:content_type] = hash[:format] # we can't use format because it's a rails reserved word
    hash[:identifier] = coerce_identifier(hash[:identifier])
    hash.merge(source_jsonld: jsonld.to_json)
  end

  # Retrieves a MARC record (serialized in XML) from Voyager using an ID
  # @return [String] string-serialized XML for the MARC record
  def marcxml
    conn = Faraday.new(url: Figgy.config[:catalog_url])
    response = conn.get("#{source_metadata_identifier}.marcxml")
    response.body
  end

  private

    # Catalog returns a hash of identifier to label now - coerce it back to a single
    # identifier.
    def coerce_identifier(identifier)
      if identifier.is_a?(Hash)
        identifier.keys.map(&:to_s).first
      else
        identifier
      end
    end

    def jsonld_request
      @jsonld_request ||=
        begin
          request = Faraday.get("#{Figgy.config[:catalog_url]}#{source_metadata_identifier}.jsonld")
          if request.status.to_s == "404"
            request = Faraday.get("#{Figgy.config[:catalog_url]}99#{source_metadata_identifier}3506421.jsonld")
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
        value.is_a?(Hash) && value[:@value] && value.key?(:@language)
      end

      def result
        if value[:@language]
          RDF::Literal.new(value[:@value], language: value[:@language])
        else
          value[:@value]
        end
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
