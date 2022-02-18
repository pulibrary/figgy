# frozen_string_literal: true

# Class for EphemeraFields as independent resources
# Please note that these are global in namespace and distinct from ControlledVocabulary::EphemeraField
# Also note that :field_name was used (as opposed to :name) for the purposes of disambiguation
class EphemeraField < Resource
  include Valkyrie::Resource::AccessControls
  attribute :field_name # Please note that this stores an index for a Term within ControlledVocabulary::EphemeraField
  attribute :member_of_vocabulary_id, Valkyrie::Types::Set
  attribute :favorite_term_ids, Valkyrie::Types::Set
  attribute :rarely_used_term_ids, Valkyrie::Types::Set
end
