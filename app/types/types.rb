# frozen_string_literal: true

module Types
  include Dry.Types(default: :nominal)
  URI = Dry::Types::Definition
    .new(RDF::URI)
    .constructor do |input|
    if input.present?
      RDF::URI.new(input.to_s)
    else
      input
    end
  end
end
