# frozen_string_literal: true
class ProcessedEvent < Valkyrie::Resource
  attribute :id, Valkyrie::Types::ID.optional
  attribute :event_id
end
