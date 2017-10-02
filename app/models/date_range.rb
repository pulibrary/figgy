# frozen_string_literal: true
class DateRange < Valhalla::Resource
  attribute :id, Valkyrie::Types::ID.optional
  attribute :start
  attribute :end
end
