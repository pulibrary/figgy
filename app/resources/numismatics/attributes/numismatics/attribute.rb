# frozen_string_literal: true

module Numismatics
  class Attribute < Resource
    include Valkyrie::Resource::AccessControls
    attribute :description
    attribute :name
  end
end
