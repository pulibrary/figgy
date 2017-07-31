# frozen_string_literal: true
class FileSet < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
  attribute :title, Valkyrie::Types::Set
  attribute :member_ids, Valkyrie::Types::Array
end
