# frozen_string_literal: true
class DateRange < Resource
  attribute :start
  attribute :end
  attribute :approximate, Valkyrie::Types::Bool
end
