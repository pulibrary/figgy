# frozen_string_literal: true
class NumismaticPlace < Resource
  include Valkyrie::Resource::AccessControls

  attribute :city, Valkyrie::Types::String
  attribute :geo_state, Valkyrie::Types::String
  attribute :region, Valkyrie::Types::String
  attribute :replaces
  attribute :depositor
end
