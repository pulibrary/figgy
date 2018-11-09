# frozen_string_literal: true
# Generated with `rails generate valkyrie:model ProxyResource`
class ProxyFile < Resource
  include Valkyrie::Resource::AccessControls

  attribute :label, Valkyrie::Types::Set
  attribute :visibility, Valkyrie::Types::Set.optional
  attribute :proxied_file_id, Valkyrie::Types::ID.optional
end
