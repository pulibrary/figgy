# frozen_string_literal: true

class MosaicFingerprintQuery
  def self.queries
    [:mosaic_fingerprint_for]
  end

  attr_reader :query_service
  delegate :adapter, to: :query_service
  delegate :connection, to: :adapter
  def initialize(query_service:)
    @query_service = query_service
  end

  def mosaic_fingerprint_for(id:)
    output = connection[fingerprint_query, id.to_s].to_a
    return id.to_s if output.blank?
    output[0][:fingerprint]
  end

  # Get all FileSets in the entire hierarchy, find the FileMetadata nodes which
  # are CloudDerivatives and have service_targets: tiles, then MD5 their IDs together.
  def fingerprint_query
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
        select md5(string_agg(file_metadata_element->'id'->>'id', ',' order by file_metadata_element->'id'->>'id')) AS fingerprint FROM deep_members,
        jsonb_array_elements(deep_members.metadata->'file_metadata') AS file_metadata_element
        WHERE deep_members.internal_resource = 'FileSet'
        AND deep_members.metadata @> '{"service_targets": ["tiles"]}'
        AND file_metadata_element @> '{"use": [{"@id": "http://pcdm.org/use#CloudDerivative"}]}'
        GROUP BY deep_members.original_id
    SQL
  end
end
