# frozen_string_literal: true
class ScannedResourceChangeSet < Valkyrie::ChangeSet
  self.fields = [:viewing_direction, :viewing_hint]
  validates_with ViewingDirectionValidator
  validates_with ViewingHintValidator
end
