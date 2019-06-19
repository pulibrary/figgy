# frozen_string_literal: true
class MediaResourceWayfinder < BaseWayfinder
  relationship_by_property :members, property: :member_ids
  relationship_by_property :file_sets, property: :member_ids, model: FileSet
  relationship_by_property :collections, property: :member_of_collection_ids
  inverse_relationship_by_property :preservation_objects, property: :preserved_object_id, singular: true, model: PreservationObject

  def audio_file_sets
    @audio_file_sets ||= file_sets.select(&:audio?)
  end
end
