# frozen_string_literal: true
class NumismaticNote < Resource
  include Valkyrie::Resource::AccessControls
  attribute :note
  attribute :type
end
