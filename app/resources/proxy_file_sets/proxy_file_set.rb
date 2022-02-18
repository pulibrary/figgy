# frozen_string_literal: true

# Generated with `rails generate valkyrie:model ProxyResource`
class ProxyFileSet < Resource
  include Valkyrie::Resource::AccessControls

  attribute :label, Valkyrie::Types::Set
  attribute :visibility, Valkyrie::Types::Set.optional
  attribute :proxied_file_id, Valkyrie::Types::ID.optional
  attribute :local_identifier

  def title
    label
  end
end
