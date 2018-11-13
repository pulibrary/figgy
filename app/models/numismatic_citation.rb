# frozen_string_literal: true
# A citation of information about a coin or issue in a reference work.  Includes the part (chapter, page, etc.) and number assigned to a specific coin (if appropriate).
class NumismaticCitation < Resource
  include Valkyrie::Resource::AccessControls
  attribute :part
  attribute :numismatic_reference_id, Valkyrie::Types::Set
  attribute :number
end
