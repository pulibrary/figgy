# frozen_string_literal: true
class EphemeraTemplate < ApplicationRecord
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
end
