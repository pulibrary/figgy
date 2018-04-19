# frozen_string_literal: true
# TODO: don't inherit from scanned resource, just copy properties?
class ScannedMapChangeSet < ScannedResourceChangeSet
  include GeoChangeSetProperties

  apply_workflow(WorkflowRegistry.workflow_for(ScannedMap))

  property :relation, multiple: false, required: false
  property :references, multiple: false, required: false

  # rubocop:disable Metrics/MethodLength
  def primary_terms
    [
      :title,
      :source_metadata_identifier,
      :rights_statement,
      :rights_note,
      :local_identifier,
      :holding_location,
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
end
