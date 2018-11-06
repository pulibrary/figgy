# frozen_string_literal: true
# Generated with `rails generate valkyrie:model Playlist`
class Playlist < Valkyrie::Resource
  include Valkyrie::Resource::AccessControls

  attribute :member_ids, Valkyrie::Types::Array
  attribute :label, Valkyrie::Types::Set
  attribute :visibility, Valkyrie::Types::Set.optional
end
