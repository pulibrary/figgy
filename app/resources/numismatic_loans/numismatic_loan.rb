# frozen_string_literal: true
class NumismaticLoan < Resource
  include Valkyrie::Resource::AccessControls
  # resources linked by ID
  attribute :firm_id
  attribute :person_id

  # descriptive metadata
  attribute :date_in, Valkyrie::Types::Date
  attribute :date_out, Valkyrie::Types::Date
  attribute :exhibit_name
  attribute :note
  attribute :type
end
