# frozen_string_literal: true
class FindBySourceMetadataIdentifier
  def self.queries
    [:find_by_source_metadata_identifier, :find_by_source_metadata_identifiers]
  end

  attr_reader :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  # Find resources by their source metadata identifier. Has logic to handle that
  # identifier potentially being an Alma ID on input.
  # @param source_metadata_identifier [String]
  # @return [Array<Valkyrie::Resource>] Resources which have the identifier.
  def find_by_source_metadata_identifier(source_metadata_identifier:)
    query_service.custom_queries.find_by_property(property: :source_metadata_identifier, value: source_metadata_identifier)
  end

  # @param source_metadata_identifiers [Array<String>]
  # @return [Array<Valkyrie::Resource>] Resources which match the given
  #   identifiers.
  def find_by_source_metadata_identifiers(source_metadata_identifiers:)
    query_service.custom_queries.find_many_by_property(property: :source_metadata_identifier, values: source_metadata_identifiers).sort_by do |resource|
      source_metadata_identifiers.index(resource.source_metadata_identifier&.first)
    end
  end
end
