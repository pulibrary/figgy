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

  # Concatenate all grandchild cloud FileMetadata node IDs and MD5 them.
  # This fingerprint can be used as an identifier for whether on not a new
  # mosaic should be generated for a RasterSet.
  def fingerprint_query
    <<-SQL
      select md5(string_agg(grandchild_metadata->'id'->>'id', ',' order by grandchild_metadata->'id'->>'id')) AS fingerprint FROM orm_resources a,
      jsonb_array_elements_text(public.get_ids(a.metadata, 'member_ids')) AS b(id)
      JOIN orm_resources c ON (b.id)::uuid = c.id,
      jsonb_array_elements_text(public.get_ids(c.metadata, 'member_ids')) AS d(id)
      JOIN orm_resources e ON (d.id)::uuid = e.id,
      jsonb_array_elements(e.metadata->'file_metadata') AS grandchild_metadata
      WHERE a.id = ?
      AND grandchild_metadata @> '{"use": [{"@id": "http://pcdm.org/use#CloudDerivative"}]}'
      GROUP BY a.id
    SQL
  end
end
