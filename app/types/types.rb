# frozen_string_literal: true
module Types
  include Dry.Types(default: :nominal)

  class CoercionError < StandardError; end

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

  DateEastern = Dry::Types::Nominal
                .new(ActiveSupport::TimeWithZone)
                .constructor do |input|
    m, d, y = input.split("/")
    raise(::Types::CoercionError, "expected format is M/D/YYYY") unless y.length == 4
    ::Time.use_zone("Eastern Time (US & Canada)") do
      ::Time.zone.parse("#{y}-#{m}-#{d}").midnight
    end
  end
end
