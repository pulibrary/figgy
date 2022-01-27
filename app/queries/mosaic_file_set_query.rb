# frozen_string_literal: true

# Returns all file sets which are marked for the mosaic service at any level
# underneath the given resource and has a generated cloud URI. Used in MosaicService.
class MosaicFileSetQuery
  def self.queries
    [:mosaic_file_sets_for]
  end

  attr_reader :query_service
  delegate :adapter, to: :query_service
  delegate :connection, to: :adapter
  delegate :run_query, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def mosaic_file_sets_for(id:)
    run_query(query, id.to_s)
  end

  # Get all FileSets in the entire hierarchy with service_targets: mosaic and
  # which have FileMetadata nodes which are CloudDerivatives
  def query
    <<-SQL
        WITH RECURSIVE deep_members AS (
          select a.id AS original_id, c.*
          FROM orm_resources a,
          jsonb_array_elements_text(public.get_ids(a.metadata, 'member_ids')) AS b(id)
          JOIN orm_resources c ON (b.id)::uuid = c.id
          WHERE a.id = ?
          UNION
          SELECT f.original_id, mem.*
          FROM deep_members f,
          jsonb_array_elements_text(public.get_ids(f.metadata, 'member_ids')) AS g(id)
          JOIN orm_resources mem ON (g.id)::uuid = mem.id
          WHERE f.metadata @> '{"member_ids": [{}]}'
        )
        select deep_members.* FROM deep_members,
        jsonb_array_elements(deep_members.metadata->'file_metadata') AS file_metadata_element
        WHERE deep_members.internal_resource = 'FileSet'
        AND deep_members.metadata @> '{"service_targets": ["mosaic"]}'
        AND file_metadata_element @> '{"use": [{"@id": "http://pcdm.org/use#CloudDerivative"}]}'
    SQL
  end
end
