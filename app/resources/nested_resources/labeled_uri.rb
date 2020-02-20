# frozen_string_literal: true

class LabeledURI < Valkyrie::Resource
  attribute :uri, Valkyrie::Types::URI
  attribute :label, Valkyrie::Types::String
end
