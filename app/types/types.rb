# frozen_string_literal: true
module Types
  include Dry.Types()
  URI = Dry::Types::Definition
        .new(RDF::URI)
        .constructor do |input|
    if input.present?
      RDF::URI.new(input.to_s)
    else
      input
    end
  end

  BetterParamsInteger = (Types::Params::Nil | Types::Params::Integer.optional)
end
