# frozen_string_literal: true
# Models events which modify resources

class Event < Valkyrie::Resource
  attribute :type, Valkyrie::Types::String
  attribute :status, Valkyrie::Types::String
  attribute :resource_id, Valkyrie::Types::ID
  attribute :child_property, Valkyrie::Types::String
  attribute :child_id, Valkyrie::Types::ID
  attribute :message, Valkyrie::Types::String
end
