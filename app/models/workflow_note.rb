# frozen_string_literal: true
class WorkflowNote < Valhalla::Resource
  attribute :id, Valkyrie::Types::ID.optional
  attribute :author
  attribute :note
end
