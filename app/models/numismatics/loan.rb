# frozen_string_literal: true
module Numismatics
  class Loan < Resource
    include Valkyrie::Resource::AccessControls
    # resources linked by ID
    attribute :firm_id
    attribute :person_id

    # descriptive metadata
    attribute :date_in
    attribute :date_out
    attribute :exhibit_name
    attribute :note
    attribute :type
  end
end
