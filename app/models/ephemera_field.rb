# frozen_string_literal: true
# Class for EphemeraFields as independent resources
# Please note that these are global in namespace and distinct from ControlledVocabulary::EphemeraField
# Also note that :field_name was used (as opposed to :name) for the purposes of disambiguation
class EphemeraField < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
  attribute :field_name # Please note that this stores an index for a Term within ControlledVocabulary::EphemeraField
  attribute :member_of_vocabulary_id
end
