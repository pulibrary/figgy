# frozen_string_literal: true
class FixityCheck < Valkyrie::Resource
  attribute :id, Valkyrie::Types::ID
  attribute :file_set_id, Valkyrie::Types::String
  attribute :file_id, Valkyrie::Types::String
  attribute :expected_checksum, Valkyrie::Types::Set
  attribute :actual_checksum, Valkyrie::Types::Set
  attribute :success, Valkyrie::Types::Int
  attribute :last_success_date, Valkyrie::Types::Set
end
