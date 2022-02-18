# frozen_string_literal: true

class Types::MutationType < Types::BaseObject
  field :update_resource, mutation: Mutations::UpdateResource
end
