# frozen_string_literal: true
class ProxyNumismaticReferenceChangeSet < Valkyrie::ChangeSet
  delegate :human_readable_type, to: :model
  property :part, multiple: false, required: false
  property :number, multiple: false, required: false
  property :numismatic_reference_id, multiple: false, required: true, type: Valkyrie::Types::ID.optional
  def primary_terms
    [
      :part,
      :number,
      :numismatic_reference_id
    ]
  end
end
