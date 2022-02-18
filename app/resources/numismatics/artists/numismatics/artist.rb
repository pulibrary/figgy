# frozen_string_literal: true

module Numismatics
  class Artist < Resource
    include Valkyrie::Resource::AccessControls
    # resources linked by ID
    attribute :person_id

    # descriptive metadata
    attribute :signature
    attribute :role
    attribute :side
  end
end
