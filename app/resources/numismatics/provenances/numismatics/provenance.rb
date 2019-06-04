# frozen_string_literal: true
module Numismatics
  class Provenance < Resource
    include Valkyrie::Resource::AccessControls
    # resources linked by ID
    attribute :firm_id
    attribute :person_id

    # descriptive metadata
    attribute :date
    attribute :note
  end
end
