# frozen_string_literal: true
# Generated with `rails generate valkyrie:model Medium`
class Medium < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
  attribute :member_ids, Valkyrie::Types::Array
  attribute :state
end
