# frozen_string_literal: true
module Types
  include Dry.Types(default: :nominal)

  # TODO: should we remove this in favor of
  # https://github.com/samvera/valkyrie/blob/60412eb1e93debd2c99745a011227c22f0da7157/lib/valkyrie/types.rb#L43
  URI = Dry::Types::Nominal
        .new(RDF::URI)
        .constructor do |input|
    if input.present?
      RDF::URI.new(input.to_s)
    else
      input
    end
  end
end
