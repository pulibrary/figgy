# frozen_string_literal: true
class NumismaticCitation < Resource
  include Valkyrie::Resource::AccessControls
  attribute :part
  attribute :numismatic_reference_id, Valkyrie::Types::Set
  attribute :number
end
