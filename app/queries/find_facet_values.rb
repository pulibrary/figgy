# frozen_string_literal: true

class FindFacetValues
  # Access the list of methods exposed for the query
  # @return [Array<Symbol>] query method signatures
  def self.queries
    [:find_facet_values]
  end

  attr_reader :query_service
  delegate :connection, to: :query_service
  delegate :resource_factory, to: :query_service
  # Constructor
  # @param query_service [Valkyrie::Persistence::Solr::QueryService] the query service for Solr
  def initialize(query_service:)
    @query_service = query_service
  end

  # Method for finding the unique values for an array of Solr facets
  # @param facet_fields [Array<String, Symbol>] array of facet field names
  # @return [Hash<Symbol, Array<FacetItem>>] resulting hash of facet fields and their values
  def find_facet_values(facet_fields:)
    run(facet_fields.map(&:to_s))
  end

  private

    # Transforms an array of solr facet values into an array of facet item objects
    # ["silver", 100, "copper", 200] -> [FacetItem, FacetItem]
    # @param solr_values [Array<String, Integer>] array of facet values returned by Solr
    # @ return [Array<FacetItem>] array of FacetItem objects
    def generate_facet_items(solr_values)
      values_hash = Hash[*solr_values]
      values_hash.map { |k, v| FacetItem.new(value: k, hits: v) }
    end

    # Generate Solr parameters
    # @param facet_fields [Array<String>] array of facet field names
    # @return [Hash] parameters
    def params(facet_fields)
      {
        q: "*",
        rows: 0,
        facet: "on",
        "facet.limit": -1,
        "facet.sort": "index",
        "facet.field": facet_fields
      }
    end

    # Execute the query and return the facet fields hash
    # @param facet_fields [Array<String>] array of facet field names
    # @return [Hash]
    def response(facet_fields)
      connection.get("select", params: params(facet_fields))["facet_counts"]["facet_fields"]
    end

    # Trigger the query and process the results
    # @param facet_fields [Array<String>] array of facet field names
    # @return [Hash<Symbol, Array<FacetItem>>] resulting hash of facet fields and their values
    def run(facet_fields)
      response(facet_fields).map do |k, v|
        [k.to_sym, generate_facet_items(v)]
      end.to_h
    end
end
