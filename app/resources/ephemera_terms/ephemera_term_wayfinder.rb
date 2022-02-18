# frozen_string_literal: true

class EphemeraTermWayfinder < BaseWayfinder
  relationship_by_property :vocabularies, property: :member_of_vocabulary_id, singular: true
end
