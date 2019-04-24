# frozen_string_literal: true
class NumismaticAttribute < Resource
  include Valkyrie::Resource::AccessControls
  attribute :description
  attribute :name
end
