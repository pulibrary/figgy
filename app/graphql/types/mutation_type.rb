# frozen_string_literal: true
class Types::MutationType < Types::BaseObject
  field :update_scanned_resource, mutation: Mutations::UpdateScannedResource
end
