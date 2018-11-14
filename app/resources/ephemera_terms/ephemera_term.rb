# frozen_string_literal: true
class EphemeraTerm < Resource
  include Valkyrie::Resource::AccessControls
  attribute :label
  attribute :uri
  attribute :code
  attribute :tgm_label
  attribute :lcsh_label
  attribute :member_of_vocabulary_id, Valkyrie::Types::Set
end
