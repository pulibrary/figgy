# frozen_string_literal: true
class ScannedResourceChangeSet < Valkyrie::ChangeSet
  property :viewing_hint, multiple: false
  property :viewing_direction, multiple: false
  validates_with ViewingDirectionValidator
  validates_with ViewingHintValidator
end
