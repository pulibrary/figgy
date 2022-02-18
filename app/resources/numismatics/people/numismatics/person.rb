# frozen_string_literal: true

module Numismatics
  class Person < Resource
    include Valkyrie::Resource::AccessControls

    attribute :name1
    attribute :name2
    attribute :epithet
    attribute :family
    attribute :born
    attribute :died
    attribute :class_of
    attribute :years_active_start
    attribute :years_active_end
    attribute :replaces
    attribute :depositor
  end
end
