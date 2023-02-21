# frozen_string_literal: true
# Generated with `rails generate valkyrie:model Playlist`
class Playlist < Resource
  include Valkyrie::Resource::AccessControls

  attribute :member_ids, Valkyrie::Types::Array.meta(ordered: true)
  attribute :title, Valkyrie::Types::Set
  attribute :visibility, Valkyrie::Types::Set.optional
  attribute :thumbnail_id
  attribute :state
  attribute :workflow_note
  attribute :auth_token, Valkyrie::Types::String
  attribute :part_of
  attribute :local_identifier
  attribute :logical_structure, Valkyrie::Types::Array.of(Structure.optional).optional
  attribute :downloadable
  attribute :depositor

  def self.can_have_manifests?
    true
  end

  # Ensure that resources of this class cannot be accessed with an access token
  # @return [Boolean]
  def self.tokenized_access?
    true
  end
end
