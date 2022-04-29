# frozen_string_literal: true
# TODO: don't inherit from scanned resource, just copy properties?
class ScannedMapChangeSet < ScannedResourceChangeSet
  include GeoChangeSetProperties

  apply_workflow(GeoWorkflow)
  enable_claiming

  property :relation, multiple: false, required: false
  property :references, multiple: false, required: false
  property :gbl_suppressed_override, multiple: false, required: false
  property :thumbnail_id, multiple: false, required: false, type: Valkyrie::Types::ID.optional

  # rubocop:disable Metrics/MethodLength
  def primary_terms
    [
      :title,
      :source_metadata_identifier,
      :gbl_suppressed_override,
      :downloadable,
      :rights_statement,
      :rights_note,
      :thumbnail_id,
      :pdf_type,
      :portion_note,
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
      :cartographic_scale,
      :coverage,
      :held_by
    ]
  end
  # rubocop:enable Metrics/MethodLength
end
