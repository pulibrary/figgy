# frozen_string_literal: true
class FileSet < Valkyrie::Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
  attribute :title, Valkyrie::Types::Set
  attribute :file_identifiers, Valkyrie::Types::Set
  attribute :member_ids, Valkyrie::Types::Array
end
