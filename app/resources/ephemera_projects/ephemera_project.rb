# frozen_string_literal: true
class EphemeraProject < Resource
  include Valkyrie::Resource::AccessControls
  attribute :member_ids, Valkyrie::Types::Array
  attribute :title, Valkyrie::Types::Set
  attribute :slug, Valkyrie::Types::Set
  attribute :top_language, Valkyrie::Types::Set
  attribute :contributor_uids, Valkyrie::Types::Set

  def logical_structure
    []
  end

  # Append contributor_uids to edit_users
  def edit_users
    (self[:edit_users] + contributor_uids).uniq
  end
end
