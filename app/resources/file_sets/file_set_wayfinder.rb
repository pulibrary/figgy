# frozen_string_literal: true

class FileSetWayfinder < BaseWayfinder
  inverse_relationship_by_property :parents, property: :member_ids, singular: true
  inverse_relationship_by_property :preservation_objects, property: :preserved_object_id, singular: true, model: PreservationObject

  def collections
    []
  end

  def members
    []
  end

  alias_method :decorated_members, :members
  alias_method :members_with_parents, :members
end
