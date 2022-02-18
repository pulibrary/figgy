# frozen_string_literal: true

class NameWithPlace < Valkyrie::Resource
  attribute :name, Valkyrie::Types::String
  attribute :place, Valkyrie::Types::String
end
