# frozen_string_literal: true
class DateRange < Resource
  attribute :id, Valkyrie::Types::ID.optional
  attribute :start
  attribute :end
end
