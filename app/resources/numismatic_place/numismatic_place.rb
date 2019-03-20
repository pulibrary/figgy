# frozen_string_literal: true
class NumismaticPlace < Valkyrie::Resource
  attribute :city, Valkyrie::Types::String
  attribute :state, Valkyrie::Types::String
  attribute :region, Valkyrie::Types::String
end
