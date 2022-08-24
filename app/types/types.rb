# frozen_string_literal: true
module Types
  include Dry.Types(default: :nominal)

  class CoercionError < StandardError; end
  EASTERN_ZONE = "Eastern Time (US & Canada)"

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
    if input.nil?
      nil
    elsif input.try(:acts_like_time?)
      # TODO: test how it behaves when passed a DateTime. Maybe roll that into
      # the string behavior? Use a check other than acts_like_time? here?
      # ::Time.parse(input.to_s).in_time_zone("Eastern Time (US & Canada)")
      raise(::Types::CoercionError, "Provide string as M/D/YYYY or Time in zone: #{EASTERN_ZONE}") unless input.time_zone.name == EASTERN_ZONE
      input
    else
      m, d, y = input.split("/")
      raise(::Types::CoercionError, "Provide string as M/D/YYYY or Time in zone: #{EASTERN_ZONE}") unless y.length == 4
      ::Time.use_zone(EASTERN_ZONE) do
        ::Time.zone.parse("#{y}-#{m}-#{d}").midnight
      end
    end
  end
end
