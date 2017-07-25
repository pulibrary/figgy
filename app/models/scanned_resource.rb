# frozen_string_literal: true
# Generated with `rails generate valkyrie:model ScannedResource`
class ScannedResource < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  include PlumSchema
  attribute :id, Valkyrie::Types::ID.optional
  attribute :member_ids, Valkyrie::Types::Array
  attribute :viewing_hint
  attribute :viewing_direction
end
