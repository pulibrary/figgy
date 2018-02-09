# frozen_string_literal: true
# TODO: don't inherit from scanned resource, just copy properties?
class ScannedMapChangeSet < ScannedResourceChangeSet
  include GeoChangeSetProperties

  apply_workflow(BookWorkflow)

  property :relation, multiple: false, required: false
  property :references, multiple: false, required: false

  # rubocop:disable Metrics/MethodLength
  def primary_terms
    [
      :title,
      :source_metadata_identifier,
      :rights_statement,
      :rights_note,
      :coverage,
      :local_identifier,
      :member_of_collection_ids,
      :append_id,
      :description,
      :subject,
      :spatial,
      :temporal,
      :issued,
      :creator,
      :language,
      :cartographic_scale
    ]
  end
  # rubocop:enable Metrics/MethodLength

  def apply_remote_metadata_directly?
    true
  end
end
