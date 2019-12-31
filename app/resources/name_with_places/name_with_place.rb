# frozen_string_literal: true
class NameWithPlace < Valkyrie::Resource
  enable_optimistic_locking

  attribute :name, Valkyrie::Types::String
  attribute :place, Valkyrie::Types::String
end
