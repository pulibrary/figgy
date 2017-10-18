# frozen_string_literal: true
class CollectionDecorator < Valkyrie::ResourceDecorator
  def title
    Array(super).first
  end

  def manageable_files?
    false
  end

  def members
    @members ||= query_service.find_inverse_references_by(resource: self, property: :member_of_collection_ids).to_a
  end

  # Nested collections are not currently supported
  def parents
    []
  end

  alias collections parents
end
