# frozen_string_literal: true
class NumismaticSubject < Resource
  include Valkyrie::Resource::AccessControls
  attribute :type
  attribute :subject
end
