# frozen_string_literal: true
class EphemeraTerm < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
  attribute :label, Valkyrie::Types::String
  attribute :uri
  attribute :code, Valkyrie::Types::Any
  attribute :tgm_label, Valkyrie::Types::Any
  attribute :lcsh_label, Valkyrie::Types::Any
  attribute :member_of_vocabulary_id
end
