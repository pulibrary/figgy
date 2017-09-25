# frozen_string_literal: true
class EphemeraTermChangeSet < Valkyrie::ChangeSet
  validates :label, :member_of_vocabulary_id, presence: true
  property :label, multiple: false, required: true
  property :uri, multiple: false, required: false
  property :code, multiple: false, required: false
  property :tgm_label, multiple: false, required: false
  property :lcsh_label, multiple: false, required: false
  property :member_of_vocabulary_id, multiple: false, required: true, type: Valkyrie::Types::ID

  def primary_terms
    [
      :label,
      :uri,
      :code,
      :tgm_label,
      :lcsh_label,
      :member_of_vocabulary_id
    ]
  end
end
