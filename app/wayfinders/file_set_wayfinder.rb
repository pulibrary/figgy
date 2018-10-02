# frozen_string_literal: true
class FileSetWayfinder < BaseWayfinder
  inverse_relationship_by_property :parents, property: :member_ids, singular: true

  def collections
    []
  end

  def members
    []
  end
  alias decorated_members members
  alias members_with_parents members
end
