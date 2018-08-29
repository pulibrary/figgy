# frozen_string_literal: true
class EphemeraTerm < Resource
  include Valkyrie::Resource::AccessControls
<<<<<<< HEAD
=======
  attribute :id, Valkyrie::Types::ID.optional
>>>>>>> d8616123... adds lux order manager to figgy
  attribute :label
  attribute :uri
  attribute :code
  attribute :tgm_label
  attribute :lcsh_label
  attribute :member_of_vocabulary_id, Valkyrie::Types::Set
end
