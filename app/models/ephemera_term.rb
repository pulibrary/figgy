# frozen_string_literal: true
class EphemeraTerm < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
  attribute :label
  attribute :uri
  attribute :code
  attribute :tgm_label
  attribute :lcsh_label
  attribute :member_of_vocabulary_id, Valkyrie::Types::Set
end
