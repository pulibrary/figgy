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
  def find_by_source_metadata_identifier(source_metadata_identifier:)
    result = query_service.custom_queries.find_by_property(property: :source_metadata_identifier, value: source_metadata_identifier)
    # If given a BibID which is for Alma, see if there's a non-Alma input.
    if result.blank? && RemoteRecord.alma?(source_metadata_identifier)
      non_alma_id = source_metadata_identifier.match(/^99([\d]*)3506421/)&.[](1)
      return result if non_alma_id.nil?
      return query_service.custom_queries.find_by_property(property: :source_metadata_identifier, value: non_alma_id)
    end
    result
  end

  def find_by_source_metadata_identifiers(source_metadata_identifiers:)
    alma_ids = source_metadata_identifiers.select do |bib_id|
      RemoteRecord.alma?(bib_id)
    end
    old_id_equivalents = alma_ids.map do |alma_id|
      alma_id.match(/^99([\d]*)3506421/)&.[](1)
    end.compact
    query_service.custom_queries.find_many_by_property(property: :source_metadata_identifier, values: source_metadata_identifiers + old_id_equivalents)
  end
end
