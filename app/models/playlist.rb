# frozen_string_literal: true
# Generated with `rails generate valkyrie:model Playlist`
class Playlist < Resource
  include Valkyrie::Resource::AccessControls

  attribute :member_ids, Valkyrie::Types::Array.meta(ordered: true)
  attribute :label, Valkyrie::Types::Set
  attribute :visibility, Valkyrie::Types::Set.optional
  attribute :thumbnail_id
  attribute :state
  attribute :workflow_note

  alias title label

  def self.can_have_manifests?
    true
  end
end
